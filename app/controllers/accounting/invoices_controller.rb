class Accounting::InvoicesController < ApplicationController
  before_action :accounts_type

  def index
    flash[:notice] = flash[:notice]
    redirect_to polymorphic_url("#{@accounts_type}Invoice".underscore.pluralize)
  end

  def show
    @invoice = crud_class.for_user(current_user).find(params[:id])
    render :template => 'accounting/invoices/show'
  end

  def create
    @invoice = crud_class.new(invoice_params)
    @success = @invoice.save
    flash[:notice] = "Invoice #{@invoice.number} is created successfully." if @success
    render :template => 'accounting/invoices/create'
  end

  def edit
    @invoice = crud_class.for_user(current_user).find(params[:id])
    render :template => 'accounting/invoices/edit'
  end

  def destroy
    @invoice = crud_class.for_user(current_user).find(params[:id])
    @invoice.destroy if @invoice.can_destroy?
    render template: 'shared/invoices/destroy'
  end

  def update
    @invoice = crud_class.for_user(current_user).find(params[:id])
    @success = @invoice.update(invoice_params)
    @invoice.to_destroy
    flash[:notice] = "Invoice #{@invoice.number} is upated successfully." if @success
    render  template: 'accounting/invoices/update'
  end

  def update_total
    @state = params["commit"] == "Create" ? "Create" : "Update"
    @invoice = crud_class.new
    line_items = invoice_params[:line_items_attributes].values rescue []
    @invoice.build_line_items(line_items)
    render :template => 'accounting/invoices/update_total'
  end

  def print
    @invoice = crud_class.for_user(current_user).find(params[:id])
    respond_to do |format|
      format.html{
        params[:online] = true
        render :template => 'accounting/invoices/print', :layout => 'print'
      }
      format.pdf{
        html = render_to_string(template: 'accounting/invoices/print', layout: 'print', formats: [:html])
        pdf = Wisepdf::Writer.new.to_pdf(html)
        send_data(pdf, :filename => "invoice #{@invoice.number}.pdf", :type => :pdf)
      }
    end
  end

  private

    def accounts_type
      @accounts_type = self.class.to_s.gsub('InvoicesController', '').gsub(/Accounting::/, '')
    end

    def invoice_params
      attrs = [
        :company_id, :date_received, :issue_date, :number,
        line_items_attributes: [
          :id, :category_id, :description, :amount, :_destroy
        ]
      ]
      params.require(:invoice).permit(attrs)
    end
end