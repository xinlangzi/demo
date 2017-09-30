class HubsController < ApplicationController

  def switch
    case params[:id]
    when /all/i
      session[:all_hubs] = params[:id]
    else
      session[:hub] = params[:id]
      session[:all_hubs] = false
    end
  end

  def index
    @hubs = Hub.with_deleted.with_default
  end

  def new
    @hub = Hub.new
  end

  def create
    @hub = Hub.new(hub_params)
    respond_to do |format|
      format.html{
        if @hub.save
          redirect_to hubs_path, notice: "Hub #{@hub.name} was created successfully."
        else
          render action: :new
        end
      }
    end
  end

  def edit
    @hub = Hub.find(params[:id])
  end

  def update
    @hub = Hub.find(params[:id])
    respond_to do |format|
      format.html{
        if @hub.update(hub_params)
          redirect_to hubs_path, notice: "Hub #{@hub.name} was updated successfully."
        else
          render action: :edit
        end
      }
    end
  end

  def destroy
    @hub = Hub.find(params[:id])
    @hub.delete
    respond_to do |format|
      format.html{
        redirect_to hubs_path, notice: "Hub #{@hub.name} was inactivated successfully."
      }
    end
  end

  def restore
    @hub = Hub.with_deleted.find(params[:id])
    @hub.restore
    respond_to do |format|
      format.html{
        redirect_to hubs_path, notice: "Hub #{@hub.name} was activated successfully."
      }
    end
  end

  private
    def hub_params
      params.require(:hub).permit(
        :name,
        :annual_inspection_expiration,
        :bobtail_insurance_expiration,
        :driver_license_expiration,
        :fuel_zone,
        :ifta_expiration,
        :last_quarterly_maintenance_expiration,
        :license_plate_expiration,
        :medical_card_expiration,
        hub_interchanges_attributes: [
          :_destroy, :customer_id, :edi, :id
        ]
      )
    end
end
