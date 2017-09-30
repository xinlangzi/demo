class HolidaysController < ApplicationController

  def index
    respond_to do |format|
      format.html
      format.json{
        fullcalendar
        render json: Holiday.range(@from, @to).map(&:to_h)
      }
    end
  end


  def create
    @holiday = Holiday.new(title: params[:title], vstart: params[:date])
    @holiday.save
    respond_to do |format|
      format.json{
        render json: @holiday.to_h
      }
    end
  end

  def update
    @holiday = Holiday.find(params[:id])
    @holiday.vstart = params[:start]
    @holiday.vend = params[:end]
    @holiday.save
    head :ok
  end

  def destroy
    @holiday = Holiday.find(params[:id])
    @holiday.destroy
    respond_to do |format|
      format.json{
        render json: { id: @holiday.id }
      }
    end
  end

end