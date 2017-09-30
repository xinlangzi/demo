class AvailStatsController < ApplicationController
  skip_before_action :check_authentication, :check_authorization, except: [:detail, :appt_range]

  def index
    @target = params[:target] || '.tiny-avail-stats'
    @tmpl = params[:tmpl] || "tiny"
    respond_to do |format|
      format.html{
        render partial: @tmpl
      }
      format.js
    end
  end

  def refresh
  end

  def appt_range
    respond_to do |format|
      format.json{
        render json: AvailStats.appt_range(current_hub)
      }
    end
  end

  def detail
    @from = Date.today
    @to = Date.today + 13.days
    @summary = AvailStats.trucker_stats(current_hub, @from, @to)
    @assigned_factors = AvailStats.assigned_weight_factors(current_hub, @from, @to)
    @unassigned_factors = AvailStats.unassigned_weight_factors(current_hub, @from.prior_business_day(1), @to.prior_business_day(1))
    @dropped_factors = AvailStats.dropped_without_appt_weight_factors(current_hub, @from.prior_business_day(3), @to.prior_business_day(3))
    @prealert_factors = AvailStats.prealerts_weight_factors(current_hub, @from.prior_business_day(1), @to.prior_business_day(1))
    @assigned_containers = AvailStats.assigned_containers(current_hub, @from, @to)
    @unassigned_containers = AvailStats.unassigned_containers(current_hub, @from.prior_business_day(1), @to.prior_business_day(1))
    @dropped_containers = AvailStats.dropped_without_appt_containers(current_hub, @from.prior_business_day(3), @to.prior_business_day(3))
    @prealert_containers = AvailStats.prealerts_containers(current_hub, @from.prior_business_day(1), @to.prior_business_day(1))
  end

end
