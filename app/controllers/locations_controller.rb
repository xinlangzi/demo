class LocationsController < ApplicationController

  layout 'track_engines'

  def index
    params[:q]||={}
    params[:q][:timestamp_from]||= Time.now.beginning_of_day.ymdhm
    params[:q][:timestamp_to]||= Time.now.end_of_day.ymdhm
    params[:q][:company_id_eq]||= 0
    params[:q].permit!
    @search = Location.search(params[:q])
    @tab_name = 'Track History'
    respond_to do |format|
      format.html
      format.json{
        @locations = @search.result.includes(:company)
        render json: @locations.map(&:to_h)
      }
    end
  end

  def track
    @tab_name = 'Real Time'
    respond_to do |format|
      format.html{
        session[:all_hubs] = true if session[:all_hubs].nil?
        @truckers = session[:all_hubs] ? Trucker.active : current_hub.truckers.active
      }
      format.json{
        if session[:all_hubs]
          data = Location.realtime.includes(:company).map(&:to_h)
        else
          data = Location.for_hub(current_hub).realtime.includes(:company).map(&:to_h)
        end
        render json: data
      }
    end
  end

  def map
    @location = Location.find(params[:id]) rescue nil
    respond_to do |format|
      format.js
      # format.html{
      #   send_data(Base64.decode64(@location.map), type: 'image/png', disposition: 'inline')
      # }
    end
  end
end
