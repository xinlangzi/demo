class Report::AppointmentsController < Report::BasesController

  def late
    default_params
    ids = Trucker.active.pluck(:id)
    @search = Operation.search(params[:q])
    @summary = Operation.move_stats(@search.result.where(trucker_id: ids))
    @lates = @search.result.late
    respond_to do |format|
      format.html
      format.csv{
        send_data(Operation.to_late_appointments_csv(@summary), filename: "late-appointments-#{Date.today.ymd}.csv")
      }
    end
  end

  def cancelled
    params[:q].try(:permit!)
    @search = CancelledAppointment.search(params[:q])
    @cancelled_appointments = @search.result.page(params[:page]).includes(:container, :trucker)
    respond_to do |format|
      format.html
      format.csv{
        send_data(CancelledAppointment.to_csv(@cancelled_appointments), filename: "cancelled-appointments-#{Date.today.ymd}.csv")
      }
    end
  end

  private
    def default_params
      params[:q]||={}
      params[:q].permit!
      params[:q][:actual_appt_gteq]||= Date.today.beginning_of_year
      params[:q][:actual_appt_lteq]||= Date.today
    end

end
