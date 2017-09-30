class DayLogsController < ApplicationController

  before_action :set_trucker

  layout 'popup'

  def index
    respond_to do |format|
      format.json{
        fullcalendar
        render json: @trucker.day_logs.range(@from, @to).map(&:to_h)
      }
    end
  end

  def show
    @day_log = @trucker.day_logs.find(params[:id])
  end

  def new
    @day_log = @trucker.day_logs.new(issue_date: params[:date])
  end

  def create
    @day_log = @trucker.day_logs.new(secure_params)
    @day_log.user = current_user
    respond_to do |format|
      if @day_log.save
        format.html{ redirect_to [@trucker, @day_log], notice: 'Day log was created successfully! You can audit now.' }
      else
        format.html{ render :new }
      end
    end
  end

  def destroy
    @day_log = @trucker.day_logs.find(params[:id])
    respond_to do |format|
      format.html{
        if @day_log.destroy
          render template: 'day_logs/deleted'
        else
          render action: 'show'
        end
      }
    end
  end

  def approve
    @day_log = @trucker.day_logs.find(params[:id])
    @day_log.approve!
    respond_to do |format|
      format.js
    end
  end

  def hosv
    @day_log = @trucker.day_logs.find(params[:id])
    @day_log.hosv!
    respond_to do |format|
      format.js
    end
  end

  def reject
    @day_log = @trucker.day_logs.find(params[:id])
    @day_log.reject!(secure_params[:comment])
    respond_to do |format|
      format.js
    end
  end

  private
    def set_trucker
      @trucker = Trucker.find(params[:trucker_id])
    end

    def secure_params
      params.require(:day_log).permit(:issue_date, :file, :comment)
    end

end
