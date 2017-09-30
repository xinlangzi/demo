class LineItemPaymentsController < LineItemsController
  def show
    @line_item_payment = LineItemPayment.find(params[:id])
    @other_line_item_payments = @line_item_payment.payment.line_item_payments 
    
    render :template => 'line_item_payments/show'
  end
end
