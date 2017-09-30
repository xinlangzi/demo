class ShippersController < CustomersClientsController
  before_action :filter_customer, only: [:autocomplete_name]

  def autocomplete_name
    name = params[:q][:shipper_name_like]
    city = params[:q][:shipper_city_like]
    state = params[:q][:shipper_state_eq]
    @shippers = Shipper.autocomplete(current_hub, @company, name, city, state, "#{params[:term]} ASC")
    render json: json_for_autocomplete(@shippers, params[:term])
  end
end
