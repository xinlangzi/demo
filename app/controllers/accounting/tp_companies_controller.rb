class Accounting::TpCompaniesController < CompaniesController
  before_action :tp_type

  before_action :get_company, only: [:show, :activate, :inactivate, :delete, :undelete]

  def index
    @status = :active
    search
  end

  def deleted
    @status = :deleted
    search
  end

  def inactive
    @status = :inactive
    search
  end

  def inactivate
    @company.inactived_at = Time.now
    save_company_and_back_to_index
    flash[:notice] = "Tp #{@tp_type} was successfully inactived." if @success
  end

  def activate
    @company.inactived_at = nil
    save_company_and_back_to_index(:status => 'inactive')
    flash[:notice] = "Tp #{@tp_type} was successfully actived." if @success
  end

  def delete
    if @company.can_delete?
      @company.deleted_at = Time.now
      @success = @company.save
      flash[:notice] = "Tp #{@tp_type} was successfully deleted." if @success
    end
    render :template => "accounting/tp_companies/delete"
  end

  def undelete
    @company.deleted_at = nil
    save_company_and_back_to_index(:status => 'deleted')
    flash[:notice] = "Tp #{@tp_type} was successfully undeleted." if @success
  end

  def show
  	render :template => "accounting/tp_companies/show"
  end

  private
    def get_company
      @company = crud_class.find(params[:id])
    end

    def tp_type
      @tp_type = self.class.to_s.gsub('Controller', '').gsub(/Accounting::Tp/, '').singularize
    end

    def save_company_and_back_to_index(params = {})
      @success = @company.save
      redirect_to polymorphic_path("Accounting::Tp#{@tp_type}".constantize.new, params)
    end

    def search
      params[:q].try(:permit!)
      @search = crud_class.for_user(current_user).send(@status).order("name ASC").search(params[:q])
      respond_to do |format|
        format.html{
          @companies = @search.result.page(params[:page])
          render template: "accounting/tp_companies/index"
        }
        format.json{
          @companies = @search.result
          render json: json_for_autocomplete(@companies, params[:term], ['url'])
        }
      end
    end
end
