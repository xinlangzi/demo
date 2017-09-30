class Mobiles::HomeController < ApplicationController
  helper TruckersHelper

  def index
    request.variant = :phone
    if current_user.is_trucker?
      @monday = Date.today.beginning_of_week
      @sunday = Date.today.end_of_week
      @cids = Container.for_user(current_user).appt_at(@monday, @sunday).pluck(:id)
      @cids+= Container.for_user(current_user).estimated_at(@monday, @sunday).pluck(:id)
      @container_charges = current_user.container_charges.where(container_id: @cids.uniq)
      @containers = Container.for_hub(current_hub).for_calendar(current_user, Date.today, Date.today).values.flatten
      @missing_j1s = J1s.missing(current_user)
      @pending_j1s  = Image.by_user(current_user).j1s.pending
      @rejected_j1s = Image.by_user(current_user).j1s.rejected
    end
  end

  def j1s
    @missing_j1s = J1s.missing(current_user)
    @pending_j1s  = Image.by_user(current_user).j1s.pending
    @rejected_j1s = Image.by_user(current_user).j1s.rejected
    respond_to do |format|
      format.html{ render layout: false }
    end
  end

end
