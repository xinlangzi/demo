class DepotsController < CompaniesController

  before_action :partial_before, only: [:new, :create, :edit, :update]

  def index
    params[:q]||={}
    params[:q][:hub_id_in] = accessible_hubs.map(&:id)
    params[:q][:hub_id_eq]||= current_hub.try(:id)
    params[:q].permit!
    @search = Depot.search(params[:q])
    respond_to do |format|
      format.html{
        @depots = @search.result.page(params[:page]).per(25)
        render template: 'depots/index'
      }
      format.json{ super }
      format.js
    end
  end

  def show
    @company = Depot.find(params[:id])
    render :template => 'companies/show'
  end

  def new
    @ssline = Ssline.find(params[:ssline_id]) rescue nil
    @company = crud_class.new
    @company.hub = current_hub
    @company.ssline = @ssline
    respond_to do |format|
      format.html { render :template => 'companies/new' }
      format.js  { render :template => 'companies/new' }
    end
  end

  def create
    @company = crud_class.new(company_params)
    respond_to do |format|
      if @company.save
        format.html{ redirect_to :action => :index }
        format.js {
          @mark = @company.class.to_s.downcase
          # @options = OperationType.build_options(current_hub, @mark, @company.ssline_id)
        }
      else
        format.html{ render :template => 'companies/new'}
        format.js  { render :template => 'companies/new' }
      end
    end
  end

  def destroy
    @company = crud_class.find(params[:id])
    if @company.destroy
      flash[:notice] = 'Depot was deleted'
    else
      flash[:notice] = "Depot couldn't be deleted"
    end
    redirect_to :action => :index
  end

  private
    def partial_before
      @partial_before = 'depots/ssline'
    end

    # def search_params
    #   params.require(:q).permit(:hub_id_eq, :customer_id_eq, :ssline_id_eq, :address_state_id_eq, :address_city_eq, :name_cont)
    # end
end
