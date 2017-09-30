class PaymentsController < ApplicationController
  before_action :accounts_type, :opposite_accounts_type

  def search
    params[:q]||={}
    params[:q].remove_empty.permit!
    @search = crud_class.for_user(current_user).search(params[:q])
    @payments = @search.result.order("issue_date DESC").page(params[:page]).per(10)
    respond_to do |format|
      format.html
    end
  end

  def index
    @search = Payment.search
    @q = (params[:q]||{}).remove_empty
    unless @q.blank?
      @q.permit!
      @q[:company_id_eq]||= @q[:customer_id_eq]||@q[:trucker_id_eq]||@q[:tp_company_id_eq]
      @q[:type_cont] = @accounts_type
      @q.remove_empty
      @search = Payment.for_user(current_user).search(@q)
      if @search.payment_no_in.blank?
        @payments = @search.result
        @total_amount = @search.result.sum(:amount)
        @total_balance = @search.result.sum(:balance)
      else
        @payments = @search.result
        @multiple = true
        render template: 'payments/show_multiple'
      end
    end
  end

  def show
    @payment = crud_class.for_user(current_user).find(params[:id])
    # render template: 'payments/show'
  end

  def new
    @filter = InvoiceFilter.new(params[:filter].remove_empty)
    company = Company.find_by(id: @filter.the_company_id)
    if company
      Adjustment.clear_up
      Credit.clear_up
      if @filter.third_party?
        relation = "Accounting::#{accounts_type}Invoice".constantize.filter(@filter).outstanding
        invoices = relation.order("issue_date ASC").distinct
        klass    = "Accounting::#{accounts_type}Payment".constantize
      else
        relation = "#{accounts_type}Invoice".constantize.filter(@filter).outstanding
        relation = relation.select("invoices.*, containers.delivered_date")
        invoices = relation.joins(line_items: :container).order("issue_date ASC, delivered_date ASC").includes(:company).distinct
        klass    = "#{accounts_type}Payment".constantize
      end
      @payment = klass.generate(company, invoices)
      @payment.optional_adjustments(invoices) rescue nil
      @payment.optional_credits(invoices)
    else
      flash[:notice] = "You have to select a company." if params[:filter]
    end
  end

  def update_total
    # render template: 'payments/update_total'
  end

  def create
    @filter = InvoiceFilter.new
    @company = Company.find(payment_params[:company_id])
    @payment = crud_class.new

    payment_attributes = payment_params
    related_adjustments = adjustment_params
    related_credits    = credit_params
    new_attributes     = payment_attributes.delete(:new_line_item_payments)

    @payment.attributes = payment_attributes
    @payment.admin = current_user if current_user.is_admin?
    @payment.related_adjustments = related_adjustments
    @payment.related_credits = related_credits
    @payment.new_line_item_payments = new_attributes

    respond_to do |format|
      format.html{
        if @payment.save
          redirect_to @payment, notice: 'Payment has been successfully created'
        else
          render template: 'payments/new'
        end
      }
      format.js{
        render template: 'payments/update_total'
      }
    end
  end

  def uncleared
    @payments = Payment.uncleared.search(type_cont: @accounts_type).result
    @selected_total = 0
    # render template: 'payments/uncleared'
  end

  def set_cleared_date
    params[:payment]||={}
    params[:payment].permit!
    params[:payment].reject!{|k, v| v[:cleared_date].blank? }
    @payments = Payment.where(id: params[:payment].keys)
    respond_to do |format|
      format.html{
        begin
          Payment.transaction do
            @payments.each do |payment|
              payment.update!(cleared_date: params[:payment][payment.id.to_s][:cleared_date])
            end
          end
        rescue ActiveRecord::RecordInvalid
          @selected_total = @payments.sum(:amount)
          render template: 'payments/uncleared'
        else
          flash[:notice] = "All payments' cleared dates have successfully been updated."
          redirect_to action: :uncleared
        end
      }
      format.js
    end
  end

  def cleared
    params[:q]||= {}
    @q = (params[:q]||{}).remove_empty
    unless @q.blank?
      @q[:type_cont] = @accounts_type
      @search = Payment.search(@q)
      @payments = @search.result
    else
      @search = Payment.search
      @payments = @search.result.none
    end
    @total_amount = @payments.map(&:amount).sum
    @total_balance = @payments.map(&:balance).sum
    respond_to do |format|
      format.html { render template: 'payments/cleared' }
    end
  end

  def edit
    @payment = crud_class.find(params[:id])
    if @payment.can_edit?
      #existing line item payment
      @payment.line_item_payments.each{|lip| lip.selected_for_payment = "1"}
      unpaid_invoices = "#{accounts_type}Invoice".constantize.unpaid(@payment.company).for_user(current_user).distinct
      @payment.optional_adjustments(unpaid_invoices) if @payment.needs_adjustments?
      invoices = (@payment.invoices + unpaid_invoices).uniq
      @payment.optional_credits(invoices)
      #new line item payment
      unpaid_invoices.each do |invoice|
        invoice.line_items.each do |li|
          @payment.line_item_payments.build(amount: li.balance, line_item_id: li.id) if li.balance > 0
        end
      end
      render template: 'payments/edit'
    else
      redirect_to @payment, notice: @payment.errors[:base].join(' ')
    end
  end

  def update
    @payment = crud_class.find(params[:id])
    # if line item payments are being selected/unselected from js, we don't want
    # to save anything because it might delete a lip from db
    Payment.transaction do
      # the attributes' order in params hash is not known, if amount goes first then
      # balance will be computed ok, but if new or existing lips hashes go first
      # then amount won't be updated on time. therefore we extract these 2 hashes from
      # params and make sure we feed all attribute hashes to the model in the correct
      # order.
      payment_attributes  = payment_params
      related_adjustments  = adjustment_params
      related_credits     = credit_params
      new_attributes      = payment_attributes.delete(:new_line_item_payments)
      existing_attributes = payment_attributes.delete(:existing_line_item_payments)

      @payment.attributes = payment_attributes
      @payment.line_item_payments.each do |lip|
        lip.payment = @payment # or else the payment will be extracted from the db
      end
      @payment.related_adjustments = related_adjustments
      @payment.related_credits = related_credits
      @payment.new_line_item_payments = new_attributes
      @payment.existing_line_item_payments = existing_attributes
      respond_to do |format|
        format.html do
          if @payment.save
            redirect_to @payment, notice: 'Payment was successfully updated.'
          else
            render template: 'payments/edit'
          end
        end
        format.js do
          render template: 'payments/update_total'
          raise ActiveRecord::Rollback, "Do not delete"
        end
      end
    end # Transaction end
  end

  def destroy
    @payment = crud_class.find(params[:id])
    begin
      @payment.destroy
      flash[:notice] = "Payment #{@payment.number} has been deleted."
    rescue =>ex
      @errors = [ex.message]
    end
    @errors||= @payment.errors[:base]
    respond_to do |format|
      format.js{ render template: 'shared/payments/destroy'}
    end
  end

  private
    def accounts_type
      @accounts_type = self.class.to_s.gsub('PaymentsController', '')
    end

    def opposite_accounts_type
      @opposite_accounts_type = @accounts_type == 'Receivable' ? 'Payable' : 'Receivable'
    end

    def payment_params
      attrs = [
        :company_id, :payment_method_id, :number, :issue_date, :date_received, :comments, :amount, :cleared_date,
        new_line_item_payments: [
          :selected_for_payment, :line_item_id, :invoice_id, :container_id, :amount
        ],
        existing_line_item_payments: [
          :selected_for_payment, :line_item_id, :invoice_id, :container_id, :amount
        ]
      ]
      params.require(:payment).permit(attrs)
    end

    def adjustment_params
      params.require(:adjustments).permit(
        params[:adjustments].keys.map do |id|
          { id => [:selected, :total, :invoice_id, :adjustment_id] }
        end
      ) rescue {}
    end

    def credit_params
      params.require(:credits).permit(
        params[:credits].keys.map do |id|
          { id => [:selected, :amount, :invoice_id, :credit_id] }
        end
      ) rescue {}
    end
end
