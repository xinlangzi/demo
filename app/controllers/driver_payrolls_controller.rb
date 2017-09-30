class DriverPayrollsController < ApplicationController

  def index
    @grouped_payments = {}
    DriverPayroll.outstanding_invoices.includes(:company).group_by(&:company).each do |company, invoices|
      @grouped_payments[company] = invoices.map do |invoice|
        PayablePayment.quick_generate(company, invoice, {}, false)
      end
    end
    session[:batch_amount] = {}
  end

  def create
    @invoice = PayableInvoice.find(params[:invoice_id])
    @payment = PayablePayment.quick_generate(@invoice.company, @invoice, secure_params)
    respond_to do |format|
      format.js
    end
  end

  def summary
    invoice = PayableInvoice.find(params[:invoice_id])
    @payment = PayablePayment.quick_generate(invoice.company, invoice, secure_params, false)
    if @payment.payment_method&&@payment.issue_date
      session[:batch_amount][invoice.id.to_s] = @payment.amount
    else
      session[:batch_amount].delete(invoice.id.to_s)
    end
    respond_to do |format|
      format.js
    end
  end

  private

  def secure_params
    params.require(:payable_payment).permit(:payment_method_id, :number, :issue_date)
  end
end