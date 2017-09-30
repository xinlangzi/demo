class ReceivableInvoicesController < InvoicesController

  def print_statement
    params[:q].permit!
    params[:q][:type_cont] = @accounts_type
    @company = Company.find(params[:q][:company_id_eq])
    @invoices = Invoice.for_user(current_user).group_by_period(params[:q])
    respond_to do |format|
      format.html{
        params[:online] = true
        render layout: 'statement'
      }
    end
  end

  def email_statement
    params[:q].permit!
    params[:q][:type_cont] = @accounts_type
    @invoice_statement = InvoiceStatement.new(invoice_statement_params)
    @company = @invoice_statement.customer
    @invoices = Invoice.for_user(current_user).group_by_period(params[:q])
    @invoice_statement.data = render_to_string(template: 'receivable_invoices/print_statement', layout: 'statement', formats: [:html])
    @invoice_statement.email
    flash[:notice] = "The email statement to customer #{@company.name} has been put into the outbox."
    redirect_to action: :index
  end

  def emailx
    params[:invoice]||={}
    params[:invoice].permit!
    ids = params[:invoice].delete(:ids)||[]
    @invoices = crud_class.for_user(current_user).where(id: ids)
    @first = @invoices.first
    if @first&&request.post?
      @period = params[:period]
      @first.attributes = params[:invoice]
      htmls = {}
      @invoices.each do |invoice|
        @invoice = invoice
        htmls[invoice.number] = render_to_string(template: 'invoice_mailer/send_invoice', layout: 'print', formats: [:html])
      end
      @info = "Send an email with invoices #{@invoices.map(&:number).join(', ')} successfully."
      @first.emailx!(@invoices, htmls)
    end
    respond_to do |format|
      format.js
    end
  end

  def email
    params[:invoice]||={}
    params[:invoice].permit!
    @invoice = ReceivableInvoice.find(params[:id])
    @invoice.attributes = params[:invoice]
    html = render_to_string(template: 'invoice_mailer/send_invoice', layout: 'print', formats: [:html])
    if @invoice.email!(html)
      flash[:notice] = "The invoice has been sent to #{@invoice.sent_to_whom} on #{@invoice.date_sent.to_date} at #{@invoice.date_sent.to_time.to_s(:time)}."
      redirect_to @invoice
		else
			flash[:notice] = "Problems occurred while sending the invoice. Check to make sure the email address is valid."
		  render template: 'invoices/show'
		end
  end

  def unemailed
    @invoices = ReceivableInvoice.unemailed.order('invoices.number DESC').page(params[:page])
    @count = ReceivableInvoice.unemailed.count

    render :template => 'receivable_invoices/unemailed'
  end

  def email_all
    @invoices = ReceivableInvoice.unemailed.all
    if @invoices.blank?
      flash[:notice] = "There are no invoices to be emailed."
    else
      edi_invoices, email_invoices = @invoices.partition{ |invoice| invoice.company.send_invoice_by_edi? }
      handle_email_invoices(email_invoices)
      handle_edi_invoices(edi_invoices)
    end
    redirect_to action: :unemailed
  end

  def preview_210
    @invoice = ReceivableInvoice.find(params[:id])
    @raw = @invoice.preview_210
  end

  def transmit_by_edi
    @invoice = ReceivableInvoice.find(params[:id])
    @invoice.transmit_by_edi!
    flash[:notice] = "The invoice has successfully been scheduled to be transmitted by EDI."
    redirect_to @invoice
  end

  private

  def handle_edi_invoices(edi_invoices)
    edi_invoices.each do |invoice|
      invoice.transmission_pending
      invoice.transmit_by_edi!
    end
  end

  def handle_email_invoices(email_invoices)
    email_invoices.each do |invoice|
      @invoice = invoice
      html = render_to_string(template: 'invoice_mailer/send_invoice', layout: 'print', formats: [:html])
      invoice.transmission_pending
      ReceivableInvoice.delay.email!(invoice.id, html)
    end
  end

  def invoice_statement_params
    attrs = [:customer_id, :subject, :body, :to]
    params.require(:invoice_statement).permit(attrs)
  end
end
