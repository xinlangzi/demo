class DropRatesController < ApplicationController
  def new
    @hub = Hub.find(params[:hub_id])
    @drop_rate = crud_class.new
  end

  def save
    params[:drop_rate].permit!
    @hub = Hub.find(params[:hub_id])
    @drop_rates = crud_class.bulk_save(@hub, params[:drop_rate].to_h)
    @success = @drop_rates.map(&:valid?).inject(&:&)
  end
end