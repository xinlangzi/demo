class Report::VacationsController < Report::BasesController

  def index
    default_params
    @search = Vacation.search(params[:q])
    @truckers = Trucker.active.search({ id_eq: @search.user_id_eq }).result
    @work_stats = Trucker.work_stats(@truckers, @search.vstart_gteq, @search.vstart_lteq)
    respond_to do |format|
      format.html
      format.csv{
        send_data(Trucker.to_work_stats_csv(@work_stats), filename: "vacation-stats.csv")
      }
    end
  end

  private
    def default_params
      params[:q]||={}
      params[:q].permit!
      params[:q][:vstart_gteq]||= Date.today.beginning_of_year
      params[:q][:vstart_lteq]||= Date.today
    end

end
