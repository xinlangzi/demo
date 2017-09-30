class Report::MaintenancesController < ApplicationController

  def index
    @search = Maintenance.search(params[:q])
    @maintenances = @search.result.page(params[:page])
  end

  def destroy
    @maintenance = Maintenance.find(params[:id])
    @maintenance.destroy
    respond_to do |format|
      format.html{
        redirect_to [:report, :maintenances], notice: "The maintenance record for #{@maintenance.trucker.name} on #{@maintenance.issue_date} was successfully deleted."
      }
    end

  end

end
