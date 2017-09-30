class Mobiles::Drivers::VacationsController < ApplicationController

  def index
    from = Date.today.beginning_of_year
    to = Date.today
    @vacations = current_user.vacations.range(from, to).where(weight_factor: 0).order("vstart DESC").pluck("DISTINCT(vstart)")
  end

end
