class QuoteEnginesController < ApplicationController

  skip_before_action :check_authentication, :check_authorization, only: [:new, :create, :cargo_weight]

  active_tab "Customer Quote" => [:index, :new, :create], "Trucker Quote" => [:search]

  def index
    redirect_to action: :new
  end

  def new
    @port = Port.find_by(name: params[:hub])
    @quote_engine = QuoteEngine.new(port_id: @port.try(:id))
    respond_to do |format|
      format.html{ redirect_to action: 'search' if current_user.try(:is_trucker?) }
      format.js
    end
  end

  def create
    @quote_engine = QuoteEngine.new(secure_params)
    @quote_engine.http_user_agent = request.env['HTTP_USER_AGENT']
    @quote_engine.who = user_id
    @valid = @quote_engine.valid?
    @spot_quotes = @quote_engine.build(current_user) if @valid
    respond_to do |format|
      format.js
    end
  end

  def cargo_weight
    respond_to do |format|
      format.js
    end
  end

  def search
    @search = Container.for_user(current_user).includes(
      operations: [:container, :trucker, :linker, :linked, :operation_type, { payable_container_charges: :chargable } ]
    ).search(params[:search])
    @containers = params[:search].blank? ? @search.result.none : @search.result.uniq
    @container_quotes = @containers.collect{|container| ContainerQuote.new(container, current_user)}
    respond_to do |format|
      format.html{ render layout: 'application' if request.variant == [:phone] }
    end
  end

  def save_charges
    @feedbacks = {}
    params[:quote]||=[]
    quote_params.each do |key, value|
      @feedbacks[key] = SpotQuote.new(value).save_charge
    end
    respond_to do |format|
      format.js
    end
  end

  private
    def secure_params
      attrs = [
        :customer_id, :port_id, :transport_style, :zip,
        :container_size_id, :container_type_id, :dest_address,
        :comment, :email_to, :rail_miles, :hazardous,
        :free_text1, :free_text2, :q_free_text1, :q_free_text2,
        cargo_weight: [], rail_road_id: [], ssline_id: []
      ]
      params.require(:quote_engine).permit(attrs)
    end

    def quote_params
      params.require(:quote).permit(
        params[:quote].keys.map do |id|
          { id => [:base_rate_fee, :fuel_amount, :toll_surcharge, :tolls_fee, :operation_id, :miles, :gallon_price] }
        end
      )
    end

end

