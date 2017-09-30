class PortsController < ApplicationController

  skip_before_action :check_authentication, :check_authorization, :only => [:index]
  active_tab "Rail Roads"
  layout 'quote_engines'

  def index
    @port = Port.find_by(id: params[:id])
    respond_to do |format|
      format.js
    end
  end

  def new
    @port = Port.new
    @port.hub = current_hub
  end

  def edit
    @port = Port.find(params[:id])
  end

  def create
    @port = Port.new(secure_params)
    respond_to do |format|
      if @port.save
        format.html{ redirect_to rail_roads_path, notice: 'Port created successfully.' }
      else
        format.html{ render :action => 'new' }
      end
    end
  end

  def update
    @port = Port.find(params[:id])
    respond_to do |format|
      if @port.update_attributes(secure_params)
        format.html{ redirect_to rail_roads_path, notice: 'Port updated successfully.' }
      else
        format.html{ render :action => 'edit' }
      end

    end
  end

  def destroy
    @port = Port.find(params[:id])
    respond_to do |format|
      if @port.destroy
        format.html{ redirect_to rail_roads_path, notice: "Port #{@port.name} deleted successfully."}
      else
        format.html{ redirect_to rail_roads_path, error: "Unable to delete port #{@port.name}"  }
      end
    end
  end

  private
    def secure_params
      attrs = [:customer_quote, :driver_quote, :hub_id, :name]
      params.require(:port).permit(attrs)
    end
end
