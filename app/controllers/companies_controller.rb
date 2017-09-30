class CompaniesController < ApplicationController

  def index
    params[:q]||= {}
    if crud_class.new.respond_to?(:hub)
      params[:q][:hub_id_in] = accessible_hubs.map(&:id)
      params[:q][:hub_id_eq]||= current_hub.try(:id)
    end
    params[:q].permit!
    @search = crud_class.for_user(current_user).active.search(params[:q])
    respond_to do |format|
      format.html{
        @companies = @search.result.page(params[:page])
      }
      format.json{
        @companies = @search.result
        render json: json_for_autocomplete(@companies, params[:term], ['url'])
      }
    end
  end

  def deleted
    @title = "Deleted #{crud_class.to_s.pluralize}"
    params[:q]||={}
    if crud_class.new.respond_to?(:hub)
      params[:q][:hub_id_in] = accessible_hubs.map(&:id)
      params[:q][:hub_id_eq]||= current_hub.try(:id)
    end
    params[:q].permit!
    @search = crud_class.for_user(current_user).deleted.search(params[:q])
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

  def show
    @company = crud_class.for_user(current_user).find(params[:id])
    respond_to do |format|
      format.html { render :template => 'companies/show'  }
      format.xml  { render :xml => @company }
    end
  end

  def new
    @company = crud_class.new
    @company.hub = current_hub if @company.respond_to?(:hub)
    respond_to do |format|
      format.html { render :template => 'companies/new' }
      format.js
    end

  end

  def create
    @company = crud_class.new(company_params)
    @company.admin = current_user if current_user.is_admin?
    respond_to do |format|
      if @company.save
        format.html {
          redirect_to polymorphic_path(@company), notice: "#{@company.name} was successfully created."
        }
        format.js {
          @mark = @company.class.try(:mark) || @company.class.to_s.downcase
          @options = OperationType.build_options(current_hub, @mark, @company.id)
        }
      else
        format.html { render template: 'companies/new' }
        format.js   { render template: 'companies/new' }
      end
    end
  end

  def edit
    @company = crud_class.for_user(current_user).find(params[:id])
    respond_to do |format|
      format.html {
        render template: 'companies/edit'
      }
      format.js{
        @tmpl = params[:type] || 'edit_popup'
      }
    end
  end

  def update
    @company = crud_class.for_user(current_user).find(params[:id])
    @company.attributes = company_params
    respond_to do |format|
      if @company.save
        format.html{ redirect_to @company, notice: "#{@company.class.to_s} was updated successfully."}
        format.js
      else
        format.html{ render :template => 'companies/edit' }
        format.js{
          @tmpl = params[:type] || 'edit_popup'
          render template: 'companies/edit'
        }
      end
    end
  end

  def undelete
    @company = crud_class.for_user(current_user).find(params[:id])
    @company.deleted_at = nil
    if @company.save
      flash[:notice] = 'Company has been successfully undeleted'
    else
      flash[:notice] = 'Company could not be undeleted'
    end
    redirect_to :action => :index
  end

  def destroy
    @company = crud_class.for_user(current_user).find(params[:id])
    flash[:notice] = 'Item was deleted from database' if @company.destroy
    respond_to do |format|
      format.html { redirect_to :action => :index }
      format.xml  { head :ok }
    end
  end

  def me
    case current_user
    when CustomersEmployee
      redirect_to current_user.customer
    when Trucker
      redirect_to current_user
    else
      redirect_to '/profile'
    end
  end

  def choose
    @company = Company.find(params[:id]) rescue nil
    respond_to do |format|
      format.js
    end
  end

  private

    def company_params
      attrs = [
        :customer_id, :ssline_id, :acct_only,
        :address_street, :address_street_2, :address_city, :address_state_id, :zip_code, :address_country,
        :billing_street, :billing_street_2, :billing_city, :billing_state_id, :billing_zip_code, :billing_country,
        :chassis_fee, :comments,
        :contact_person, :edi_customer_code, :extra_contact_info,
        :fax, :fein, :for_container, :hub_id, :invoice_j1s,
        :lat, :lng, :name, :onfile1099, :ophours,
        :phone, :phone_extension, :phone_mobile, :print_name,
        :rail_fee, :rail_road_id, :ssn, :use_edi, :web,
        :email, :accounting_email, :eq_team_email, :rail_billing_email,
        email: [], accounting_email: [], eq_team_email: [], rail_billing_email: [], collection_email: [],
        free_outs_attributes: [:_destroy, :container_size_id, :container_type_id, :days, :id]
      ]
      params.require(:company).permit(attrs)
    end

end
