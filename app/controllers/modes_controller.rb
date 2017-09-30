class ModesController < ApplicationController

  def driver
    session[:driver_mode] = !session[:driver_mode]
  end

end
