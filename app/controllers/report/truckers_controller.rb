class Report::TruckersController < Report::CompaniesController

  def performance
    default_params
    @filter = DriverPerformanceFilter.new(params[:filter])
    @performances = DriverPerformance.evaluation(@filter.from, @filter.to)
  end

  private
    def default_params
      params[:filter]||={}
      params[:filter][:from]||= Date.today.beginning_of_week(:sunday) - 6.months
      params[:filter][:to]||= Date.today.beginning_of_week(:sunday)
    end

end
