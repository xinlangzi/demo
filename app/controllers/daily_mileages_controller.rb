class DailyMileagesController < ApplicationController

  def index
    @search = DailyMileage.for_user(current_user).for_hub(current_hub).order("day DESC").search(params[:q])
    @daily_mileages = @search.result.page(params[:page]).includes([{ truck: :trucker }, { state_mileages: :state } ])
  end

  def show
    @daily_mileage = DailyMileage.for_user(current_user).find(params[:id])
  end

  def new
    @daily_mileage = DailyMileage.new(day: Date.today)
    @daily_mileage.set_trucker(current_user.id) if current_user.is_trucker?
    render :template => 'daily_mileages/new'
  end

  def create
    @daily_mileage = DailyMileage.new(secure_params)
    respond_to do |format|
      format.html{
        if @daily_mileage.save
          flash[:notice] = "Daily mileage has been successfully recorded."
          redirect_to daily_mileages_path
        else
          flash[:notice] = "Mileage couldn't be saved."
          render action: 'new'
        end
      }
      format.js{ render 'daily_mileages/refresh' }
      format.json{
        if @daily_mileage.save
          render json: { location: daily_mileages_path(submitted_at: Time.now.to_i) }, status: :created
        else
          render json: @daily_mileage.errors.full_messages, status: :unprocessable_entity
        end
      }
    end
  end

  def edit
    @daily_mileage = DailyMileage.for_user(current_user).find(params[:id])
    @daily_mileage.trucker_id = @daily_mileage.truck.trucker_id
  end

  def update
    @daily_mileage = DailyMileage.for_user(current_user).find(params[:id])
    @daily_mileage.attributes = secure_params
    respond_to do |format|
      format.html{
   		  if @daily_mileage.save
      		flash[:notice] = "Daily mileage successfully updated."
      		redirect_to daily_mileages_path
    		else
          flash[:notice] = "Daily mileage couldn't be saved."
      		render action: 'edit'
    		end
      }
      format.js{ render 'daily_mileages/refresh' }
      format.json{
        if @daily_mileage.save
          render json: { location: daily_mileages_path(submitted_at: Time.now.to_i) }, status: :created
        else
          render json: @daily_mileage.errors.full_messages, status: :unprocessable_entity
        end
      }
    end
  end

  def destroy
    @daily_mileage = DailyMileage.for_user(current_user).find(params[:id])
    flash[:notice] = "Mileage has been deleted" if @daily_mileage.destroy
    redirect_to daily_mileages_path
  end

  def report
    quarter = params[:quarter].try(:permit!)
    if current_user.is_admin?
      @truckers = Trucker.where(id: DailyMileage.truckers.map(&:id) + FuelPurchase.truckers.map(&:id))
      @trucker = Trucker.find_by(id: quarter[:trucker_id]) rescue nil
    else
      @trucker = current_user
    end

    @years = (DailyMileage.years(@trucker) + FuelPurchase.years(@trucker)).uniq.sort

    @fuel_purchases = @state_mileages = nil

    if quarter&&@years.present?
      @state_mileages = StateMileage.quarterly(quarter[:year], quarter[:quarter], @trucker)
      @fuel_purchases = FuelPurchase.quarterly(quarter[:year], quarter[:quarter], @trucker)
    end
  end

  private

    def secure_params
      attrs = [
        :trucker_id, :day, :start, :end, :truck_id,
        state_mileages_attributes: [:state_id, :miles, :_destroy]
      ]
      params.require(:daily_mileage).permit(attrs)
    end

end
