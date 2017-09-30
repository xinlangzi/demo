class Mobiles::Drivers::MaintenancesController < ApplicationController

  def index
    @maintenances = Maintenance.for_user(current_user).page(params[:page]).per(10)
  end

  def show
    @maintenance = Maintenance.for_user(current_user).find(params[:id])
  end

  def new
    @maintenance = Maintenance.for_user(current_user).build
  end

  def create
    @maintenance = Maintenance.for_user(current_user).new(secure_params)
    files = params[:files].permit!
    respond_to do |format|
      format.json{
        if @maintenance.save_with_files(files.values)
          render json: {
            location: mobiles_drivers_maintenances_path(submitted_at: Time.now.to_i),
            message: "The maintenance record on #{@maintenance.issue_date} was successfully submitted."
          }, status: :created
        else
          render json: @maintenance.errors.full_messages, status: :unprocessable_entity
        end
      }
    end
  end

  def destroy
    @maintenance = Maintenance.for_user(current_user).find(params[:id])
    respond_to do |format|
      format.json{
        if @maintenance.destroy
          render json: {
            location: mobiles_drivers_maintenances_path(submitted_at: Time.now.to_i),
            message: "The maintenance record on #{@maintenance.issue_date} was successfully deleted."
          }, status: :created
        else
          render json: @maintenance.errors.full_messages, status: :unprocessable_entity
        end
      }
    end
  end

  private
    def secure_params
      params.require(:maintenance).permit(:issue_date, :services)
    end

end
