class TrucksController < ApplicationController

  before_action :set_truck, only: [:show, :edit, :update, :destroy, :assign]

  def new
    @truck = Truck.new(trucker_id: params[:trucker_id])
  end

  def create
    @truck = Truck.new(secure_params)
    @truck.trucker = current_user if current_user.is_trucker?
    if @truck.save
      flash[:notice] = "Truck has been successfully created"
      redirect_to @truck
    else
      flash[:notice] = "Truck couldn't be saved"
      render :new
    end
  end

  def show
  end

  def edit
  end

  def update
    if @truck.update_attributes(secure_params)
      flash[:notice] = "Truck has been updated successfully"
      redirect_to @truck
    else
      render :edit
    end
  end

  def destroy
    flash[:notice] = "Truck has been deleted" if @truck.destroy
    redirect_to @truck.trucker
  end

  def assign
    @truck = @truck.assign!(secure_params[:owner_id])
    redirect_to @truck, notice: "Truck was assigned to new owner successfully"
  rescue =>ex
    redirect_to @truck, notice: ex.message
  end

  private

    def secure_params
      attrs = [
        :default, :trucker_id, :owner_id, :number, :license_plate_no,
        :vin, :gvwr, :make, :model, :year, :tire_size,
        :tai_expiration, :bobtail_insurance_expiration, :ifta_expiration, :ifta_applicable,
        :last_quarterly_maintenance_report, :license_plate_expiration,
        state_ids: []
      ]
      params.require(:truck).permit(attrs)
    end

    def set_truck
      @truck = Truck.find(params[:id])
    end

end
