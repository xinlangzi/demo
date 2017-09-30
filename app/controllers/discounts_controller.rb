class DiscountsController < ApplicationController
  active_tab "Discounts"
  layout "quote_engines"
  def index
    @rate_for_all_customers = Discount.rate_for_all_customers
    @rate_for_all_truckers = Discount.rate_for_all_truckers
  end

  def create
    @discount = Discount.new(secure_params)
    @success = @discount.save
    @discount.amount = nil if @success
    respond_to do |format|
      format.js
    end
  end

  def update
    @discount = Discount.find(params[:id])
    @discount.update_attributes(secure_params)
    respond_to do |format|
      format.js
    end
  end

  private

  def secure_params
    params.require(:discount).permit(:amount, :company_id)
  end
end
