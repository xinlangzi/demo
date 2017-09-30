class AdjustmentsController < ApplicationController

  before_action :set_adjustment, only: [:update, :destroy]

  def index
    params[:q]||={}
    @search = Adjustment.joins(:invoice).search(params[:q])
    @total_amount = @search.result.sum(:amount)
    @adjustments = @search.result.page(params[:page]).order("invoices.issue_date DESC").includes([{ invoice: :company }, :payment])
  end

  def new
    @adjustment = Adjustment.new
    @adjustment.invoice_id = params[:invoice_id]
    @adjustment.amount = 0
    @adjustment.save(validate: false)
  end

  def update
    @success = @adjustment.update(secure_params)
    @invoice = @adjustment.invoice.reload
  end

  def destroy
    @success = @adjustment.destroy
    @invoice = @adjustment.invoice
  end

  private

    def set_adjustment
      @adjustment = crud_class.find(params[:id])
    end

    def secure_params
      params.require(:adjustment).permit(:amount, :comment, :category_id)
    end
end
