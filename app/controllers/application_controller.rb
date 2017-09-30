class ApplicationController < ActionController::Base
  include Pundit
  include AutoSessionTimeout
  include ParamsToPermit

  auto_session_timeout 1800 #seconds

  clear_helpers
  helper_method :current_user,
                :current_hub,
                :accessible_hubs,
                :cowner,
                :crud_class,
                :alter_status_icon,
                :accessible?,
                :accessible_url?,
                :in_payable?,
                :in_receivable?,
                :driver_mode?,
                :mobile_or_tablet?

  before_action :cowner
  before_action :set_request_variant
  before_action :check_authentication,
                :check_authorization,
                :check_user_proxy,
                :check_system_settings,
                :set_paper_trail_whodunnit,
                except: [
                  :login, :logout, :switch_user,
                  :forward_sms_to_email, :retrieve_password,
                  :email_sent, :set_password, :reset_email
                ]

  class HubError < StandardError; end

  rescue_from ActiveRecord::RecordNotFound do |ex|
    render template: 'errors/unauthorized', layout: (current_user ? 'application' : 'blank')
  end

  rescue_from Pundit::NotAuthorizedError do
    render template: 'errors/unauthorized', layout: (current_user ? 'application' : 'blank')
  end

  rescue_from HubError do |ex|
    render template: 'errors/hub'
  end

  def crud_class
    self.class.to_s.gsub('Controller', '').singularize.constantize
  end

  def logged_in?
    !user_id.nil?
  end

  def current_user
    @current_user||= User.find_by(id: session[:uid])
  end

  def in_payable?
    /payable/.match(controller_name).present?
  end

  def in_receivable?
    /receivable/.match(controller_name).present?
  end

  def driver_mode?
    session[:driver_mode]
  end

  def accessible_hubs
    Hub.with_default.for_user(current_user)
  end

  private

    def current_hub
      @current_hub||= fetch_hub
    end

    def fetch_hub
      return current_user.hub if current_user.try(:is_trucker?)
      session[:hub]||= Hub.default(current_user).try(:name)
      hub = Hub.for_user(current_user).find_by(name: session[:hub])
      raise HubError unless hub
      hub
    end

    def set_request_variant
      request.variant = case true
      when mobile_or_tablet?
        :phone
      when /\/mobiles\/home/.match(request.referrer).present?
        :phone
      end
    end

    def check_system_settings
      return true if session[:system_setup]
      unless SystemSetting.setup?
        if current_user.is_superadmin?
          flash[:notice] = 'Please config the system first'
          redirect_to new_system_setting_path
        else
          redirect_to_login('Please contact your system admin to configure the system first')
        end
      else
        session[:system_setup] = true
      end
    end

    def login_from_cookie
      unless session[:uid]
        user = User.from_cookie(cookies)
        if user
          session[:uid] = user.id
          send_remember_cookie!
        end
      end
    end

    # This method returns a logged in user id
    def user_id
      login_from_cookie
      cookies.signed[:uid] = session[:uid]
    end

    def check_authentication
      unless user_id
        redirect_to_login
        return false
      end
    end

    def accessible_url?(url)
      path = Rails.application.routes.recognize_path(url)
      accessible?(path[:controller], path[:action])
    end

    def accessible?(controller_path, action_name)
      current_user.has_access?(controller_path, action_name)
    end

    def check_authorization
      User.restore_session(session[:uid], request)
      case current_user.type
      when 'SuperAdmin'
        @admin = current_user
      when 'Admin'
        @admin = current_user
      when 'Trucker'
        @trucker = current_user
      when 'CustomersEmployee'
        @customer = current_user.customer
      when 'Crawler'
        @crawler = current_user
      else
        redirect_to_login("Oops! Who are you?")
        return false
      end

      unless accessible?(self.class.controller_path, action_name)
        logger.info("denied path is #{self.class.controller_path} and action is #{action_name}")
        render template: 'errors/unauthorized'
        return false
      end
    end

    def cowner
      @owner||= Owner.first
    end

    def redirect_to_home
      flash[:notice]||= ""
      case true
      when mobile_or_tablet?
        redirect_to_mobile_home
      else
        redirect_to_normal_home
      end
    end

    def redirect_to_mobile_home
      redirect_to mobiles_home_index_path
    end

    def redirect_to_normal_home
      if session[:redirect]
        redirect_to_previous_url
      else
        if current_user.is_superadmin? && !Owner.valid?
          flash[:notice]+= "Information on owner is incomplete."
          redirect_to edit_owner_path(Owner.itself)
        else
          flash[:notice]+= "You were automatically redirected to your home page."
          redirect_to my_account_url
        end
      end
    end

    def redirect_to_previous_url
      redirect_url = request.protocol + request.host + (request.port ? ":" +request.port.to_s : '') + session[:redirect]
      flash[:notice]+= "You were redirected to your original requested page."
      session[:redirect] = nil
      redirect_to redirect_url
    end

    def redirect_to_login(message="")
      redirect_url = params[:redirect] || request.fullpath
      session[:uid] = nil
      flash[:notice] =  message
      session[:redirect] = redirect_url if request.format.html?
      redirect_to login_path
      return false
    end

    def handle_remember_cookie!(remember_me)
      return if current_user.nil?
      case true
      when current_user.valid_token?(cookies)
        current_user.refresh_token
      when remember_me
        current_user.remember_me
      else
        current_user.forget_me
      end
      send_remember_cookie!
    end

    def send_remember_cookie!
      cookies[:auth_token] = { value: current_user.remember_token, expires: current_user.remember_token_expires_at }
    end

    def fullcalendar
      beginning = (params[:start].nil? ? Date.today : Date.parse(params[:start]) + 1.week).beginning_of_month
      @from = (beginning - 1.week).to_date
      @to = (beginning.end_of_month + 1.week).to_date
    end

    def driver_pane_data
      date = params[:date]
      @driver_statuses = Trucker.load_miles(current_hub, date)
      @driver_scores = DriverPerformance.scores
      @containers_by_trucker = Operation.containers_by_trucker(date)
      @missing_j1s = J1s.number_of_missing.count_by(&:owner_id)
      @pending_j1s = Image.pending_j1s.count_by(&:user_id)
    end

    def expire_avail_stats
      expire_fragment([current_hub, 'avail_stats'])
      PrivatePub.publish_to("/avail_stats", "AvailStats.reload()") rescue nil
    end

    def alter_status_icon(object, attr, auto_save=false)
      case true
      when object.try(attr).blank?
        'pending-entry'
      when object.has_alter_request?(attr)
        auto_save ? 'save-success' : 'pending-approval-alter'
      else
        'approval-alter'
      end
    end

    def mobile_or_tablet?
      browser.device.mobile? || browser.device.tablet?
    end

    def check_user_proxy
      ## avoid to proxy user by non-admin
      if current_user.try(:is_admin?)
        proxy_id = params[:user_proxy] if params[:user_proxy]
        unless proxy_id
          request.referrer =~/\/mobiles\/home\?user_proxy=(\d+)/
          proxy_id = $1
        end
        ## only query trucker then replace @current_user
        @current_user = Trucker.find_by(id: proxy_id) if proxy_id
      end
    end



    # # temp methods for rails 5 strong parameters
    # def strong_params(hash)
    #   hash.map do |key, value|
    #     if value.is_a?(Hash)
    #       hash = /_attributes$/.match(key) ? value.values.first : value
    #       { key.to_sym => strong_params(hash) }
    #     else
    #       key.to_sym
    #     end
    #   end
    # end

    # def strong_params_helper(hash, attrs=[])
    #   new_attrs = strong_params(hash)
    #   more = new_attrs - attrs
    #   attrs+= new_attrs
    #   puts '*-*'*20
    #   attrs = attrs.uniq.sort do |a, b|
    #     case true
    #     when a.is_a?(Hash)
    #       1
    #     when b.is_a?(Hash)
    #       -1
    #     else
    #       a <=> b
    #     end
    #   end
    #   puts attrs.each_slice(5).map{|x| x.map{|y| ":#{y}"}.join(", ")+ ","}
    #   puts '*-*'*20
    #   raise "Have more attrs to permit: #{more}" unless more.empty?
    #   attrs
    # end

end
