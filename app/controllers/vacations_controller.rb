class VacationsController < ApplicationController

  def index
    respond_to do |format|
      format.html
      format.json{
        fullcalendar
        render json: Vacation.for_user(current_user).for_hub(current_hub).range(@from, @to).includes(:user).map(&:to_h)
      }
    end
  end

  def create
    @vacation = Vacation.new(user_id: params[:user_id], vstart: params[:date])
    @vacation.save
    # expire_driver_pane(@vacation.vstart.ymd)
    expire_avail_stats
    respond_to do |format|
      format.json{
        render json: @vacation.to_h
      }
    end
  end

  def update
    @vacation = Vacation.find(params[:id])
    @vacation.vstart = params[:start]
    @vacation.vend = params[:end]
    @vacation.save
    expire_avail_stats
    head :ok
  end

  def adjust
    @vacation = Vacation.find(params[:id])
    @vacation.adjust
    # expire_driver_pane(@vacation.vstart.ymd)
    expire_avail_stats
    respond_to do |format|
      format.json{
        render json: @vacation.to_h
      }
    end
  end

end