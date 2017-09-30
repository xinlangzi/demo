class Accounting::PaymentsController < ApplicationController
  before_action :accounts_type

  def index
    redirect_to polymorphic_path("#{@accounts_type}Payment".underscore.pluralize)
  end

  def new
    redirect_to new_polymorphic_path("#{@accounts_type}Payment".constantize, filter: filter_params.to_h)
  end

  def create
    @filter = InvoiceFilter.new
    @payment = crud_class.new(payment_params)
    @payment.related_credits = credit_params
    if @payment.save
      flash[:notice] = 'Payment has been successfully created'
      redirect_to @payment
    else
      render template: 'payments/new'
    end
  end

  def show
    @payment = crud_class.for_user(current_user).find(params[:id])
    render template: 'accounting/payments/show'
  end

  def edit
    @payment = crud_class.for_user(current_user).find(params[:id])
    if @payment.can_edit?
      invoices = "Accounting::#{accounts_type}Invoice".constantize.where(company_id: @payment.company_id).distinct
      @payment.load_line_item_payments(invoices)
      @payment.optional_credits(invoices)
      render template: 'accounting/payments/edit'
    else
      flash[:notice] = @payment.errors[:base].join(' ')
      redirect_to @payment
    end
  end

  def update
    @payment = crud_class.for_user(current_user).find(params[:id])
    @payment.related_credits = credit_params
    if @payment.update_attributes(payment_params)
      flash[:notice] = 'Payment was successfully updated.'
      redirect_to @payment
    else
      render template: 'accounting/payments/edit'
    end
  end

  def destroy
    begin
      @payment = crud_class.for_user(current_user).find(params[:id])
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

  def update_total
    @payment = crud_class.new
    @payment.build_line_item_payments((params["payment"]["line_item_payments_attributes"].map{|li| li[1]} rescue []))
    @payment.related_credits = credit_params
    render template: 'accounting/payments/update_total'
  end

  private
    def accounts_type
      @accounts_type = self.class.to_s.gsub('PaymentsController', '').gsub(/Accounting::/, '')
    end

    def payment_params
      attrs = [
        :company_id, :payment_method_id, :issue_date, :number, :comments,
        line_item_payments_attributes: [
          :id, :line_item_id, :amount, :selected_for_payment
        ]
      ]
      params.require(:payment).permit(attrs)
    end

    def credit_params
      params.require(:credits).permit(
        params[:credits].keys.map do |id|
          { id => [:selected, :amount, :invoice_id, :credit_id] }
        end
      ) rescue {}
    end

    def filter_params
      params.require(:filter).permit(:tp_company_id) rescue {}
    end
end