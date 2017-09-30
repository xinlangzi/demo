class BaseRatesController < ApplicationController
  active_tab "Base Rates" => [:index, :sample]
  layout "quote_engines"
  before_action :check_access_token, only: [:export]
  skip_before_action :check_authentication, :check_authorization, only: [:export]

  def index
    @demo = Hub.demo
    @hubs = Hub.all
    respond_to do |format|
      format.html
      format.json{
        render json: Analysis::BaseRate.chart_data(params[:hub_id])
      }
    end
  end

  def configure
    Rails.cache.write(:base_rate_mile_step, params[:mile_step])
    Rails.cache.write(:base_rate_csv, params[:csv].read) if  params[:csv]
    Rails.cache.write(:base_rate_hub_ids, params[:hub_ids])
    respond_to do |format|
      format.html{
        redirect_to base_rates_path
      }
    end
  end

  def sample
    @hub = Hub.find(params[:id])
    @sample = Analysis::BaseRate.sample(params[:id])
    respond_to do |format|
      format.html
    end
  end

  def export
    q = {}
    q[:hub_id_eq] = params[:hub_id] if params[:hub_id].present?
    @mile_rates = MileRate.search(q).result
    @customer_rates = CustomerRate.search(q).result
    @driver_rates = DriverRate.search(q).result
    @drop_rates = DropRate.search(q).result
  end

  def import
    render plain: BaseRate.import(params[:url])
  end

  def copy
    from = Hub.find(params[:from])
    to = Hub.find(params[:to])
    BaseRate.copy(from, to)
    respond_to do |format|
      format.html{
        redirect_to base_rates_path
      }
    end
  end

  private
  def check_access_token
    token = params[:access_token]
    unless token.present?&&(token == Rails.application.secrets.access_token)
      render template: 'errors/unauthorized'
      return false
    end
  end
end
