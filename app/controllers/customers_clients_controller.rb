class CustomersClientsController < CompaniesController

  before_action :partial_before, only: [:new, :create, :edit, :update]

  def index
    params[:q]||={}
    params[:q][:customer_id_eq] = current_user.customer.id if current_user.is_customer?
    params[:q][:hub_id_in] = accessible_hubs.map(&:id)
    params[:q][:hub_id_eq]||= current_hub.try(:id)
    params[:q].permit!
    @search = crud_class.search(params[:q])
    @clients = @search.result.page(params[:page]).per(25)
    respond_to do |format|
      format.html
      format.json{ super }
      format.js
    end

  end

  def new
    @company = crud_class.new
    @company.hub = current_hub
    if current_user.is_customer?
      @company.customer = current_user.customer
    elsif current_user.is_admin?
      @company.customer = Customer.find(params[:customer_id]) if params[:customer_id]
    end
    respond_to do |format|
      format.html { render :template => 'companies/new' }
      format.js
    end
  end

  def create
    @company = crud_class.new(company_params)
    @company.customer = current_user.customer if current_user.is_customer?
    respond_to do |format|
      if @company.save
        format.html {
          flash[:notice] = "#{@company.class.to_s} was successfully created."
          redirect_to polymorphic_path(@company)
        }
        format.js {
          @mark = @company.class.to_s.downcase
          @options = OperationType.build_options(current_hub, @mark, @company.customer_id)
        }
      else
        format.html { render :template => 'companies/new' }
        format.js   { render :template => 'companies/new' }
      end
    end
  end

  def destroy
    @company = crud_class.for_user(current_user).find(params[:id])
    if @company.destroy
      flash[:notice] = 'Item was deleted from database'
    end
    respond_to do |format|
      format.html { redirect_to :action => :index }
      format.xml  { head :ok }
    end
  end

  private
    def filter_customer
      customer_id = current_user.is_customer? ? current_user.id : params[:q][:customer_id_eq]
      customer_id = current_user.id if customer_id.to_s.blank?
      @company = Company.find(customer_id)
    end

    def partial_before
      @partial_before = 'customers_clients/customer'
    end

    # def search_params
    #   params.require(:q).permit(:hub_id_eq, :customer_id_eq, :ssline_id_eq, :address_state_id_eq, :address_city_eq, :name_cont)
    # end
end
