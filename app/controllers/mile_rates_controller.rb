class MileRatesController < ApplicationController

  def update
    @hub = Hub.find(params[:hub_id])
    @mile_rate = MileRate.default(@hub)
    @success = @mile_rate.update_attributes(secure_params)
    respond_to do |format|
      format.js
    end
  end

  private

  def secure_params
    attrs = [:key_fuel_price, :avg_mpg, :regular, :triaxle]
    params.require(:mile_rate).permit(attrs)
  end
end