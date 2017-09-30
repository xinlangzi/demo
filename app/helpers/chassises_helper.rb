module ChassisesHelper
  include ContainersHelper

  def mark_selected(tag)
    session[:chassis_tags].include?(tag) rescue false
  end
end
