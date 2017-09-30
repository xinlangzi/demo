class Mobiles::Drivers::InspectionsController < ApplicationController

  def index
    @inspections = Inspection.for_user(current_user).page(params[:page]).per(5)
  end

end
