class DriverRatesController < ApplicationController

  def new
    @hub = Hub.find(params[:hub_id])
    @driver_rate = DriverRate.new
  end

  def save
    params[:driver_rate].permit!
    @hub = Hub.find(params[:hub_id])
    @driver_rates = DriverRate.bulk_save(@hub, params[:driver_rate].to_h)
    @success = @driver_rates.map(&:valid?).inject(&:&)
  end

end