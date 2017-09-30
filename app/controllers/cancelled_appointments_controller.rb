class CancelledAppointmentsController < ApplicationController
  before_action :set_cancelled_appointment, only: [:edit, :update, :destroy]

  # POST /cancelled_appointments
  # POST /cancelled_appointments.json
  def create
    @cancelled_appointment = CancelledAppointment.new(secure_params)

    respond_to do |format|
      if @cancelled_appointment.save
        format.js{ flash[:notice] = 'Cancelled appointment was successfully created.' }
      else
        format.js{ render :new }
      end
    end
  end

  # GET /cancelled_appointments/1/edit
  # GET /cancelled_appointments/1/edit.json
  def edit
    @container = @cancelled_appointment.container
  end

  # PATCH/PUT /cancelled_appointments/1
  # PATCH/PUT /cancelled_appointments/1.json
  def update
    respond_to do |format|
      if @cancelled_appointment.update(secure_params)
        format.html { redirect_to [:cancelled, :report, :appointments], notice: 'Cancelled appointment was successfully updated.' }
      else
        format.html { render :edit }
      end
    end
  end

  # DELETE /cancelled_appointments/1
  # DELETE /cancelled_appointments/1.json
  def destroy
    @cancelled_appointment.destroy
    respond_to do |format|
      format.html { redirect_to [:cancelled, :report, :appointments], notice: 'Cancelled appointment was successfully destroyed.' }
      format.js
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_cancelled_appointment
      @cancelled_appointment = CancelledAppointment.find(params[:id])
    end

    def secure_params
      attrs = [:container_id, :issue_date, :reason, :trucker_id]
      params.require(:cancelled_appointment).permit(attrs)
    end
end
