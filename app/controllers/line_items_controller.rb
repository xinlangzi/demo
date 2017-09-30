class LineItemsController < ApplicationController

  def index

  end

  def show
    @line_item = crud_class.find(params[:id])
    @line_item_payments = @line_item.payments
    @other_line_items = @line_item.invoice.line_items

    render :template => 'line_items/show'
  end

  def update

  end

  def destroy
    @line_item = crud_class.find(params[:id])
  end


  def double_invoiced
    @double_invoiced_line_items = []
    LineItem.find_each do |li|
      @double_invoiced_line_items << li unless li.valid?
    end
  end

end
