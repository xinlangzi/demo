class InvoicesController < ApplicationController
  before_action :accounts_type, :opposite_accounts_type

  def autocomplete_number
    params[:q]||={}
    params[:q][:type_cont] = @accounts_type
    params[:q][:number_eq] = params[:credit][:invoice_id]
    @invoices = Invoice.search(params[:q]).result.order("issue_date DESC")
    render json: json_for_autocomplete(@invoices, params[:term])
  end

  def search
    params[:q]||={}
    params[:q].remove_empty.permit!
    @search = crud_class.for_user(current_user).search(params[:q])
    @invoices = @search.result.order("issue_date DESC").page(params[:page]).per(10)
    respond_to do |format|
      format.html
    end
  end

  def show
    includes = [
      {
        line_items: [
          :invoice,
          :payments,
          {
            container: [
              { container_charges: :chargable },
              { operations: [ { company: :address_state } ] }
            ]
          }
        ]
      }
    ]
    @invoice = crud_class.for_user(current_user).includes(includes).find(params[:id])
    @accounts_type = @invoice.class.to_s.gsub('Invoice', '')
    respond_to do |format|
      format.html
      format.iif
    end
  end

  def print
    @invoice = crud_class.for_user(current_user).find(params[:id])
    respond_to do |format|
      format.html{
        params[:online] = true
        render template: 'invoice_mailer/send_invoice', layout: 'print'
      }
      format.pdf {
        html = render_to_string(template: 'invoice_mailer/send_invoice', layout: 'print', formats: [:html])
        pdf = Wisepdf::Writer.new.to_pdf(html)
        send_data(pdf, :filename => "invoice #{@invoice.number}.pdf", :type => :pdf)
      }
    end
  end

  def index
    params[:q]||={}
    @q = params[:q].remove_empty.permit!
    @q[:company_id_eq]||= @q[:customer_id_eq] || @q[:trucker_id_eq] || @q[:tp_company_id_eq]
    @q[:type_cont] = @accounts_type
    @q.remove_empty
    if @q[:invoice_no_in].blank?
      @search = Invoice.for_user(current_user).search(@q)
      @outstanding = @search.outstanding_true.to_boolean
      @time = params[:time]
      @invoices = Invoice.for_user(current_user).group_by_period(@q, @time)
      respond_to do |format|
        format.html { render template: 'invoices/index' }
        format.js   { render template: 'shared/invoices/show_all' }
        format.csv  {
          @invoices = @invoices.values.map{|h| h[:invoices]}.inject(:+)
          params[:name]||= "#{@accounts_type}_Invoices_#{params[:time]}"
          send_data(Invoice.outstanding_csv(@invoices), type: 'text/csv; charset=utf-8; header=present', filename: "#{params[:name]}.csv")
        }
      end
    else
      @search = Invoice.for_user(current_user).search(@q)
      @invoices = @search.result
      @multiple = true
      render 'invoices/show_multiple'
    end
  end

  # Generates an invoices for these containers
  def new
    @uncharged_containers = Container.delivered.uncharged(accounts_type)
    @filter = AccountingContainerFilter.new(params[:filter].remove_empty)
    @company = Company.find(@filter.the_company_id) rescue nil
    if @company
      if @filter.third_party?
        @invoice = "Accounting::#{@accounts_type}Invoice".constantize.new(company_id: @company.id)
      else
      # See container.rb scope: payable_operations_complete_enough_to_invoice
      # @containers = Container.filter(@filter).uninvoiced_cached(accounts_type).order("delivered_date ASC").all
        @containers = Container.filter(@filter)
                               .uninvoiced_cached(accounts_type)
                               .includes([:customer, { operations: [:company, :trucker] } ])
                               .to_a.sort_by{|c| c.delivered_date.to_i}.uniq
        @invoice = crud_class.generate(@company, @containers) unless @containers.blank?
      end
    else
      flash[:notice] = "You have to select a company." if params[:filter]
    end
  end

  def batch
    @invoices = []
    batch_companies.each do |company|
      filter = AccountingContainerFilter.new(company_id: company.id)
      containers = Container.filter(filter)
                            .uninvoiced_cached(accounts_type)
                            .includes([:customer, { operations: [:company, :trucker] } ])
                            .to_a.sort_by{|c| c.delivered_date.to_i}.uniq
      @invoices <<  crud_class.generate(company, containers) unless containers.blank?
    end
  end


  def update_total
    @invoice = crud_class.new(invoice_params)
    line_item_params.to_h.each_value do |li|
      if li[:selected_for_invoice].to_boolean
        line_item = @invoice.line_items.build(li)
        line_item.invoice = @invoice # I need the invoice object to do validations on amount
      end
    end
    @invoice.amount = @invoice.computed_amount
  end


  def create
    begin
      params[:line_items]||={}
      @invoice = crud_class.new(invoice_params)
      containers = []
      @invoices = []
      @batch = params[:batch].to_boolean
      line_item_params.to_h.each do |id, li|
        if li[:selected_for_invoice].to_boolean
          container = Container.find_by(id: id)
          if container
            containers << container
            @invoice.add_line_item(container)
          end
        end
      end
      raise "Invalid Invoice" unless @invoice.valid?
      if @invoice.generate_multiple.to_boolean
        containers.uniq.each do |container|
          invoice = crud_class.new(invoice_params)
          invoice.add_line_item(container)
          invoice.save!
          @invoices << invoice
        end
        numbers = @invoices.map(&:number)
        flash[:notice] = "Invoices #{numbers.join(', ')} saved successfully."
        @redirect_url = polymorphic_path(@invoice.class, q: { invoice_no_in: numbers.join(',') })
      else
        @invoice.save!
        @invoices << @invoice
        flash[:notice] = "Invoice #{@invoice.number} saved successfully."
        @redirect_url = polymorphic_path(@invoice)
      end
    rescue => ex
      logger.error(ex.message)
    end
  end

  def edit
    @invoice = crud_class.for_user(current_user).includes(
      [ { line_items: [ { container: [:customer, { operations: :trucker }] }, :invoice, :payments] } ]
    ).find(params[:id])
    @filter = AccountingContainerFilter.new({ company_id: @invoice.company_id })
    # @uninvoiced_containers = Container.filter(@filter).uninvoiced_cached(accounts_type).order("delivered_date ASC").all
    @uninvoiced_containers = Container.filter(@filter)
                                      .uninvoiced_cached(accounts_type)
                                      .includes([:customer, { operations: [:trucker] } ])
                                      .to_a.sort_by{|c| c.delivered_date.to_i}.uniq
    render :template => 'invoices/edit'
  end

  def update_total_on_edit
    @invoice = crud_class.for_user(current_user).find(params[:id])
    @invoice_amount = BigDecimal("0.0")
    line_item_params.to_h.each do |id, li|
      @selected = true if li[:selected_for_invoice] == "1" || li[:selected_new_for_invoice] == "1"
      @invoice_amount += BigDecimal(li[:amount]) if li[:selected_for_invoice] == "1"
      @invoice_amount += Container.find(id).amount(crud_class.to_s.gsub('Invoices',''), @invoice.company.id) if li[:selected_new_for_invoice] == "1"
    end
    @invoice_amount+= params[:adjustments].to_f
  end



  def update
    @invoice = crud_class.for_user(current_user).find(params[:id])
    @invoice_amount = BigDecimal("0.0")
    @invoice.attributes = invoice_params
    has_line_items = false
    line_item_params.to_h.each do |id, li|
      # If existing line item was unchecked then delete it only if there are no payments.
      if li[:selected_for_invoice] == "0"
        unselected = LineItem.find(id)
        @invoice.delete_line_item(unselected) if unselected.payments.blank?
      end
      # If new containers have been selected, then add them to invoice as line items.
      @invoice.add_line_item(Container.find(id)) if li[:selected_new_for_invoice] == "1"
      has_line_items = true if li[:selected_for_invoice] == "1" || li[:selected_new_for_invoice] == "1"
    end
    if !has_line_items
      # if invoice is empty (no line items), and delete it.
      @invoice.destroy
      flash[:notice] = "Invoice #{@invoice.number} has been deleted because it didn't have any line items."
      @redirect_url = polymorphic_path(crud_class)
    elsif @invoice.valid?
      @invoice.save!
      flash[:notice] = "Invoice #{@invoice.number} was successfully updated."
      @redirect_url = polymorphic_path(@invoice)
    else
      flash[:notice] = "Could not update invoice #{@invoice.number}."
    end
  end

  def history
    @invoice = crud_class.for_user(current_user).find(params[:id])
    render template: 'invoices/history'
  end


  def destroy
    @invoice = crud_class.for_user(current_user).find(params[:id])
    @invoice.destroy if @invoice.can_destroy?
    render template: 'shared/invoices/destroy'
  end

  def quick_book
    @q = (params[:q]||{}).remove_empty
    @q.delete(:outstanding_true) unless @q[:outstanding_true].to_boolean
    @q[:company_id_eq]||= @q[:customer_id_eq] || @q[:trucker_id_eq] || @q[:tp_company_id_eq]
    @q[:type_cont] = @accounts_type
    @search = Invoice.for_user(current_user).search(@q)
    @outstanding = @search.outstanding_true
    @invoices = @search.result.page(params[:page])
    respond_to do |format|
      format.iif {
        @invoices.update_all(exported_to_quickbooks: true)
        render(iif: render_to_string, filename: "#{crud_class}-#{Time.zone.now.strftime('%Y-%m-%d')}")
      }
      format.html
    end
  end
  #
  # Some utility functions
  #
  private
  # returns Payable or Receivable string
  def accounts_type
    @accounts_type||= self.class.to_s.gsub('InvoicesController', '')
  end

  # returns Payable if Accts. Receivable and vice versa
  def opposite_accounts_type
    @opposite_accounts_type = @accounts_type == 'Receivable' ? 'Payable' : 'Receivable'
  end

  def batch_companies
    case params[:target].gsub(/\s/, '_').strip
    when /^truckers/i
      Trucker.uninvoiced(accounts_type)
    when /^tp_vendors/i
      Company.third_party.uninvoiced(accounts_type)
    when /^customers/i
      Customer.uninvoiced(accounts_type)
    when /^tp_customers/i
      Company.third_party.uninvoiced(accounts_type)
    when /^others/i
      Company.other.uninvoiced(accounts_type)
    else
      Company.none
    end
  end

  def invoice_params
    attrs = [:auto_number, :number, :comments, :company_id, :generate_multiple, :issue_date]
    params.require(:invoice).permit(attrs)
  end

  def line_item_params
    params.require(:line_items).permit(
      params[:line_items].keys.map do |id|
        { :"#{id}" => [:id, :amount, :selected_for_invoice, :selected_new_for_invoice] }
      end
    )
  end

end
