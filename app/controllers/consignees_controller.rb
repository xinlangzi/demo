class ConsigneesController < CustomersClientsController
  before_action :filter_customer, only: [:autocomplete_name]

  def autocomplete_name
    name = params[:q][:consignee_name_like]
    city = params[:q][:consignee_city_like]
    state = params[:q][:consignee_state_eq]
    @consignees = Consignee.autocomplete(current_hub, @company, name, city, state, "#{params[:term]} ASC")
    render json: json_for_autocomplete(@consignees, params[:term])
  end

end
