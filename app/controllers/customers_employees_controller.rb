class CustomersEmployeesController < UsersController
  before_action :for_customer, only: [:index, :new, :create, :show]

  def index
    params[:q]||={}
    params[:q][:customer_id_eq]||= @for_customer.try(:id)
    super
  end

  def new
    @company = crud_class.new
    @company.customer = @for_customer
  end

  def create
    @company = crud_class.new(company_params)
    @company.customer = @for_customer
    @company.admin = current_user if current_user.is_admin?
    respond_to do |format|
      if @company.save
        format.html {
          flash[:notice] = 'User was successfully created.'
          redirect_to(customers_employee_url(@company))
        }
        format.js
      else
        format.html{ render :new }
        format.js{ render :new }
      end
    end
  end

  def show
    @company = nil
    @company = crud_class.find(params[:id]) if current_user.is_admin?
    @company = @for_customer.employees.find(params[:id]) if current_user.is_customer?
  end

  def edit
    @company = crud_class.for_user(current_user).find(params[:id])
    @for_customer = @company.customer
  end

  def update
    @company = crud_class.for_user(current_user).find(params[:id])
    @for_customer = @company.customer
    @company.attributes = company_params
    @company.password_confirmation = company_params[:password_confirmation] if @company.change_pwd
    @company.admin = current_user if current_user.is_admin?
    if @company.save
      flash[:notice] = "User updated successfully"
      redirect_to @company
    else
      render :edit
    end
  end

  private

    def for_customer
      if current_user.is_admin?
        id = params[:customer_id] || company_params[:customer_id] rescue nil
        @for_customer = Customer.find_by(id: id)
      elsif current_user.is_customer?
        @for_customer = current_user.customer
      else
        raise 'authorization error: only admin and customer should see this page'
      end
    end

    def company_params
      attrs = [
        :change_pwd, :comments, :customer_id, :email, :name,
        :password, :password_confirmation,
      ]
      params.require(:company).permit(attrs)
    end
end
