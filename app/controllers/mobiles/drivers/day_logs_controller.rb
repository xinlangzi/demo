class Mobiles::Drivers::DayLogsController < ApplicationController

  def index
    respond_to do |format|
      format.json{
        fullcalendar
        render json: current_user.day_logs.range(@from, @to).map(&:to_h)
      }
    end
  end

  def show
    @day_log = current_user.day_logs.find(params[:id])
    respond_to do |format|
      format.html{ render layout: false }
    end
  end

  def new
    @day_log = current_user.day_logs.build
    @day_log.issue_date = params[:date]
    respond_to do |format|
      format.html{ render layout: false }
    end
  end

  def create
    respond_to do |format|
      format.json{
        begin
          raise 'Please upload day log' if file_params.values.empty?
          file_params.values.map do |file|
            day_log = DayLog.new(secure_params)
            day_log.file = file
            day_log.trucker = current_user
            day_log.user = current_user
            day_log.save!
          end
          message = "You uploaded the captured day log successfully."
          render json: { message: message, js: "CloseAjaxPopup();DayLog.refreshCalendar()" }, status: :created
        rescue => ex
          render json: [ex.message], status: :unprocessable_entity
        end
      }
    end
  end

  def destroy
    begin
      @day_log = DayLog.delete_by!(params[:id], current_user)
    rescue => ex
      @error = ex.message
    end
    respond_to do |format|
      format.json{
        if @error
          render json: @error, status: :unprocessable_entity
        else
          render json: { message: 'Daily log was deleted successfully.' }, status: :ok
        end
      }
    end
  end

  private
    def secure_params
      params.require(:day_log).permit(:issue_date)
    end

    def file_params
      params.require(:files).permit! rescue {}
    end

end
