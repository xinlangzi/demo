class CustomerQuotesController < ApplicationController

  def quick
    @customer_quote = CustomerQuote.new(secure_params)
    @quote = @customer_quote.quick
  end

  private

    def secure_params
      params.require(:quote).permit(:rail_road_id, :destination)
    end
end
