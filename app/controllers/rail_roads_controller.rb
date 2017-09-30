class RailRoadsController < ApplicationController
  active_tab "Rail Roads"
  layout 'quote_engines'

  def index
    @ports = Port.all
    @port = Port.find(params[:port_id]) rescue nil
    @roads = @port.nil? ? [] : @port.rail_roads
    respond_to do |format|
      format.html
    end
  end

  def new
    @road = RailRoad.new
  end

  def edit
    @road = RailRoad.find(params[:id])
  end

  def create
    @road = RailRoad.new(secure_params)
    respond_to do |format|
      if @road.save
        flash[:notice] = 'Rail road created successfully.'
        format.html{redirect_to rail_roads_path}
      else
        format.html {render :action => 'new' }
      end
    end
  end


  def update
    @road = RailRoad.find(params[:id])
    respond_to do |format|
      if @road.update_attributes(secure_params)
        flash[:notice] = 'Rail road updated successfully.'
        format.html{redirect_to rail_roads_path}
      else
        format.html {render :action => 'edit' }
      end

    end

  end

  def destroy
    @road = RailRoad.find(params[:id])
    @port = @road.port
    respond_to do |format|
      if @road.destroy
        flash[:notice] = "Road #{@road.name} was deleted"
      else
        flash[:notice] = "Road #{@road.name} couldn't be deleted"
      end
      format.html{redirect_to rail_roads_path}
     end
  end

  private
    def secure_params
      attrs = [:name, :lon, :lan, :port_id, :weight_rank2_fee, :chassis_dray]
      params.require(:rail_road).permit(attrs)
    end
end
