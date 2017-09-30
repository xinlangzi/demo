class GoogleMapController < ApplicationController
  skip_before_action :check_authentication, :check_authorization, :only => [:routes, :geocode]

  def routes
   @rail_roads = RailRoad.where(id: params[:rrid])
  end

  def geocode
    @locations = GoogleMap.geocode(params[:address])
  end

end
