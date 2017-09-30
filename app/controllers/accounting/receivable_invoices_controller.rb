class Accounting::ReceivableInvoicesController < Accounting::InvoicesController

  def email
    @invoice = Accounting::ReceivableInvoice.find(params[:id])
    @invoice.attributes = email_params
    html = render_to_string(template: 'accounting/invoices/print', layout: 'print', formats: [:html])
    if @invoice.email!(html)
      flash[:notice] = "The invoice has been sent at #{@invoice.date_sent.us_datetime}."
      redirect_to @invoice
		else
			flash[:notice] = "Problems occured while sending the invoice"
		  render template: 'accounting/invoices/show'
		end
  end

  private

    def email_params
      params.require(:invoice).permit(:email_to, :email_subject)
    end
end