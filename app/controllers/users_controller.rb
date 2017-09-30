class UsersController < CompaniesController

  MARKET_LAYOUT = [
    :login,
    :retrieve_password,
    :reset_email,
    :set_password,
    :email_sent
  ]

  layout Proc.new { |controller| (mobile_or_tablet?) ? "application" : (MARKET_LAYOUT.include?(controller.action_name.to_sym) ? 'market' : 'application') }

  def profile
    @company = current_user
    respond_to do |format|
      format.html do |html|
        html.none { render template: "companies/edit" }
        html.phone
      end
    end
  end

  def login
    respond_to do |format|
      format.html{
        notices = []
        try_to_login unless current_user
        if request.get?
          handle_remember_cookie!(true) if current_user # Remember automatically when login with token from mobile
        else
          if @user.try(:email_to_reset?)
            destroy_session
            redirect_to reset_email_path(email: @user.email)
            return
          end
          if current_user
            handle_remember_cookie!(user_params[:remember_me] == "1")
            if current_user.is_admin? && current_user.last_login
              notices << "Your last login was on #{current_user.last_login.us_datetime}. "
            end
            current_user.update_column(:last_login, Time.now)
          else
            notices << "Invalid user/password combination."
          end
        end
        flash[:notice] = notices.uniq.join(" ")
        redirect_to_home if current_user
      }
    end
  end

  def logout
    destroy_session
    cookies.signed[:uid] = nil
    redirect_to login_path
  end

  def my_account
  end

  def settings
  end

  def edit
    @company = crud_class.for_user(current_user).find(params[:id])
    respond_to do |format|
      format.html { render :template => 'companies/edit'}
      format.xml  { render :xml => @company }
    end
  end

  def update
    @company = crud_class.for_user(current_user).find(params[:id])
    @company.attributes = company_params
    if @company.change_pwd
      @company.password_confirmation = company_params[:password_confirmation]
    end
    @company.admin = current_user if current_user.is_admin?
    if @company.save
      flash[:notice] = "#{@company.class.to_s} #{@company.name} was updated successfully!"
      redirect_to @company
    else
      render template: 'companies/edit'
    end
  end

  def retrieve_password
    @info = User.request_set_password(params) if request.post?
    success = @info == User::SET_PASSWORD_REQUEST_APPROVED
    respond_to do |format|
      format.html{
        redirect_to email_sent_path if success
      }
    end
  end

  def set_password
    flash[:notice] = User.set_password(params, request.post?)
    respond_to do |format|
      format.html
    end
  end

  def reset_email
    flash[:notice] = nil
    flash[:notice] = User.reset_email(params[:name], params[:email], params[:new_email]) if request.post?
    respond_to do |format|
      format.html
    end
  end

  def switch_user
    begin
      destroy_session
      user_id = params[:scope_identifier].gsub(/\D/, '')
      session[:uid] = user_id
      User.restore_session(session[:uid], request)
      cookies.signed[:uid] = session[:uid]
      @current_user = nil
      flash[:notice] = "Login as #{current_user.name} at #{Time.now.us_datetime}"
      redirect_to('/my_account')
    rescue => ex
      redirect_to('/')
    end
  end

  private

    def try_to_login
      if params[:token]
        session[:uid] = User.auth_by_token(params[:token]).try(:id)
      else
        params[:user]||={}
        params[:user][:email]||= params[:email]
        params[:user][:password]||= params[:password]
        @user = User.new(user_params)
        session[:uid] = @user.try_to_login(request).try(:id)
      end
      cookies.signed[:uid] = session[:uid]
    end

    def user_params
      params.require(:user).permit(:email, :password, :remember_me)
    end

    def destroy_session
      if current_user
        current_user.forget_me
        send_remember_cookie!
      end
      reset_session
      User.restore_session(session[:uid], request)
    end


    def company_params
      attrs = [
        :hub_id, :name, :contact_person, :extra_contact_info, :email, :accounting_email,
        :print_name, :fein, :onfile1099,
        :phone, :phone_extension, :phone_mobile, :fax,
        :address_street, :address_street_2, :address_city, :address_state_id, :zip_code,
        :billing_street, :billing_street_2, :billing_city, :billing_state_id, :billing_zip_code,
        :change_pwd, :password, :password_confirmation,
        :lat, :lng, :comments
      ]
      attrs+= [
        :dl_no, :dl_haz_endorsement, :dl_state_id, :dl_expiration_date,
        :hire_date, :termination_date,
        :medical_card_expiration_date,
        :ssn, :date_of_birth, :week_pay,
        hub_ids: []
      ] if current_user.is_admin?
      params.require(:company).permit(attrs)
    end
end
