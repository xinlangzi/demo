class SystemSettingsController < ApplicationController

  skip_before_action :check_system_settings,
    only: [:new, :create, :edit, :update]

  # GET system_setting
  # GET system_setting/1.xml
  def show
    if @system_setting = SystemSetting.default
      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @system_setting }
      end
    else
      redirect_to new_system_setting_url
    end
  end

  # GET system_setting/new
  # GET system_setting/new.xml
  def new
    if SystemSetting.count == 0
      @system_setting = SystemSetting.new

      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @system_setting }
      end
    else
      redirect_to edit_system_setting_url
    end
  end

  # GET system_setting/1/edit
  def edit
    @system_setting = SystemSetting.default
  end

  # POST system_setting
  # POST system_setting.xml
  def create
    @system_setting = SystemSetting.new(secure_params)

    respond_to do |format|
      if @system_setting.save
        flash[:notice] = 'System basic configuration was successfully created.'
        format.html { redirect_to(system_setting_path) }
        format.xml  { render :xml => @system_setting, :status => :created, :location => @system_setting }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @system_setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT system_setting/1
  # PUT system_setting/1.xml
  def update
    @system_setting = SystemSetting.default

    respond_to do |format|
      if @system_setting.update_attributes(secure_params)
        flash[:notice] = 'System basic configuration was successfully updated.'
        format.html { redirect_to(system_setting_url) }
        format.xml  { head :ok }
      else
        flash[:notice] = nil
        format.html { render :action => "edit" }
        format.xml  { render :xml => @system_setting.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE system_setting/1
  # DELETE system_setting/1.xml
  def destroy
    @system_setting = SystemSetting.default
    @system_setting.destroy

    respond_to do |format|
      format.html { redirect_to(new_system_setting_url) }
      format.xml  { head :ok }
    end
  end

  private

  def secure_params
    attrs = [
      :account_sid, :additional_drayage, :auth_token, :caller_id_phone, :default_bcc_email,
      :default_fine_print, :dispatch_email, :driver_hr_email, :driver_hr_manager, :driver_hr_phone,
      :tasks_for_hired_driver, :tasks_for_terminated_driver,
      :driver_quote_bcc_to, :facebook_url, :fuel_zone, :godaddy_seal_url, :google_plus_url,
      :incomplete_address_email_to, :inspection_reward, :invoice_statement_bcc, :invoice_statement_body, :invoice_statement_from,
      :invoice_statement_subject, :quote_bcc_to, :quote_email_from, :state_id, :three_day_accrual_drop_fine_print,
      :twitter_url, :two_day_accrual_drop_fine_print, :unsure_of_ssl_chassis_fine_print,
      :google_map_api_key_frontend, :google_map_api_key_backend,
      :ds_username, :ds_password, :ds_integrator_key,
      :ds_account_id, :ds_endpoint, :ds_api_version,
      :ds_psp_template_id, :ds_contract_driver_template_id, :ds_owner_operator_template_id,
      :ds_admin_name, :ds_admin_email
    ]
    params.require(:system_setting).permit(attrs)
  end
end
