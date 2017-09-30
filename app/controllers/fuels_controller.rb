class FuelsController < ApplicationController
  active_tab "Fuel Fee"
  layout "quote_engines"
  def index
    @fuels = Fuel.page(params[:page]).includes(:hub)
    respond_to do |format|
      format.html
      format.xml  { render :xml => @fuel }
    end
  end

  def create
    Fuel.create(secure_params)
    respond_to do |format|
      format.html { redirect_to fuels_path }
    end
  end

  private
    def secure_params
      params.require(:fuel).permit(:hub_id, :price)
    end
end
