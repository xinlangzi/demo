class TruckersController < UsersController

  def show
    @company = Trucker.for_user(current_user).find(params[:id])
    @drug_tests = @company.drug_tests
    @trucks = @company.trucks

    respond_to do |format|
      format.iif
      format.html
    end
  end

  def export_active_to_csv
    respond_to do |format|
      format.csv{
        csv_data = Trucker.to_csv(current_hub.truckers.active.all)
        send_data(csv_data, filename: 'active-truckers.csv')
      }
    end
  end

  def export_inactive_to_csv
    respond_to do |format|
      format.csv{
        csv_data = Trucker.to_csv(current_hub.truckers.inactive.all)
        send_data(csv_data, filename: 'inactive-truckers.csv')
      }
    end
  end

  def export_all_to_csv
    respond_to do |format|
      format.csv{
        csv_data = Trucker.to_csv(current_hub.truckers.all)
        send_data(csv_data, filename: 'all-truckers.csv')
      }
    end
  end

  def inactive
    @title = "Inactive Truckers"
    params[:q]||={}
    params[:q][:hub_id_in] = accessible_hubs.map(&:id)
    params[:q][:hub_id_eq]||= current_hub.try(:id)
    @search = Trucker.for_user(current_user).inactive.search(params[:q])
    respond_to do |format|
      format.html{
        @companies = @search.result.page(params[:page])
        render :template => 'companies/index'
      }
      format.json{
        @companies = @search.result
        render json: json_for_autocomplete(@companies, params[:term], ['url'])
      }
    end
  end

  def expiration_dates
    @truckers = current_hub.truckers.active.all
  end

  def tasks
    @company = Trucker.for_user(current_user).find(params[:id])
    @company.update_tasks(params[:type], params[:tasks])
    @done = @company.tasks_done?(params[:type])
    respond_to do |format|
      format.js
    end
  end

end
