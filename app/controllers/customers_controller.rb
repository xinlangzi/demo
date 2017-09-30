class CustomersController < CompaniesController

  skip_before_action :check_authentication, :check_authorization, only: [:matched]

  def show
    @company = crud_class.for_user(current_user).find(params[:id])
    @customers_employees = @company.employees
    respond_to do |format|
      format.html
      format.iif
    end
  end

  def matched
    emails = params[:email].split(/[;|,]/).map(&:strip)
    customer = Company.match_customer(emails)
    respond_to do |format|
      format.json{
        if customer
          render json: { message: 'Registered customer found' }, status: :created
        else
          render json: { error: 'No registered customer' }, status: :unprocessable_entity
        end
      }
    end
  end
end
