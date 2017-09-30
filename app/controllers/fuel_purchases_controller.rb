class FuelPurchasesController < ApplicationController

  def index
    @search = FuelPurchase.for_user(current_user).for_hub(current_hub).order("fuel_purchases.day DESC, fuel_purchases.id DESC").search(params[:q])
    @purchase_numbers = @search.result
    @fuel_purchases = @search.result.page(params[:page]).includes([ :trucker, :truck, :purchase_state])
  end

  def show
    @fuel_purchase = FuelPurchase.for_user(current_user).find(params[:id])
  end

  def new
    @fp = FuelPurchase.new(day: Date.today)
    @fp.purchase_state = SystemSetting.default.state
    @fp.set_trucker(current_user.id) if current_user.is_trucker?
  end

  def create
    params[:fuel_purchase][:trucker_id] = current_user.id if current_user.is_trucker?
    params[:fuel_purchase][:user_id] = current_user.id
    @fp = FuelPurchase.new(secure_params)
    respond_to do |format|
      format.html{
        if @fp.save
          flash[:notice] = "Fuel purchase has been successfully recorded."
          redirect_to fuel_purchases_path
        else
          flash[:notice] = "Fuel purchase couldn't be saved."
          render action: 'new'
        end
      }
      format.js{ render 'fuel_purchases/refresh' }
      format.json{
        if @fp.save
          render json: { location: fuel_purchases_path(submitted_at: Time.now.to_i) }, status: :created
        else
          render json: @fp.errors.full_messages, status: :unprocessable_entity
        end
      }
    end
  end

  def edit
    @fp = FuelPurchase.for_user(current_user).find(params[:id])
  end

  def update
    @fp = FuelPurchase.for_user(current_user).find(params[:id])
    params[:fuel_purchase][:user_id] = current_user.id
    @fp.attributes = secure_params
    respond_to do |format|
      format.html{
        if @fp.save
          flash[:notice] = "Fuel purchase has been successfully updated."
          redirect_to fuel_purchases_path
        else
          flash[:notice] = "Fuel purchase couldn't be saved."
          render action: 'edit'
        end
      }
      format.js{ render 'fuel_purchases/refresh' }
      format.json{
        if @fp.save
          render json: { location: fuel_purchases_path(submitted_at: Time.now.to_i) }, status: :created
        else
          render json: @fp.errors.full_messages, status: :unprocessable_entity
        end
      }
    end
  end

  def destroy
    @fp = FuelPurchase.for_user(current_user).find(params[:id])
    if @fp.destroy
      flash[:notice] = "Fuel purchase has been deleted."
    else
      flash[:notice] = "Fuel purchase couldn't be deleted."
    end
    redirect_to fuel_purchases_path
  end

  private

    def secure_params
      attrs = [
        :user_id, :trucker_id, :truck_id, :day, :purchase_state_id, :gallons, :price, :odometer, :file
      ]
      params.require(:fuel_purchase).permit(attrs)
    end
end
