class CustomerRatesController < ApplicationController

  def new
    @hub = Hub.find(params[:hub_id])
    @customer_rate = CustomerRate.new
  end

  def save
    params[:customer_rate].permit!
    @hub = Hub.find(params[:hub_id])
    @customer_rates = CustomerRate.bulk_save(@hub, params[:customer_rate].to_h)
    @success = @customer_rates.map(&:valid?).inject(&:&)
  end

end