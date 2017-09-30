class User < Company

  attr_accessor :password, :remember_me, :tried_to_login
  attr_accessor :password_confirmation, :remember_me, :change_pwd

  has_and_belongs_to_many :roles, join_table: "roles_users"
  has_many :bulk_quotes
  has_many :vacations, dependent: :destroy
  has_many :alter_requests, dependent: :destroy

  validates_presence_of :email
  validates_uniqueness_of :email, :scope => [:deleted_at]

  validates_presence_of :password, :on => :create
  validates_confirmation_of :password, :on => :create

  validates_presence_of :password, :on => :update, :if => :change_pwd
  validates_confirmation_of :password, :on => :update, :if => :change_pwd
  validates_presence_of :password_confirmation, :on => :update, :if => :change_pwd

  validates_each :password, :on => :update do |user, attribute, value|
    if !user.change_pwd && user.changed.include?("password")
      user.errors.add :password, "should not be changed if change_pwd is not set (checked)"
    end
  end

  validates :email, single_email: true

  belongs_to :admin
  has_one :calendar_header, class_name: 'CalendarHeader', foreign_key: 'company_id', dependent: :destroy
  has_one :order_stack_header, class_name: 'OrderStackHeader', foreign_key: 'company_id', dependent: :destroy
  has_many :spot_quotes, dependent: :nullify
  # active rewritten to work with companies that don't need approval
  scope :email_like, ->(email){ where("email LIKE ?", "%#{email}%")}
  scope :active, ->{ where("companies.deleted_at IS NULL AND companies.admin_id IS NOT NULL").order("companies.name ASC") }
  scope :inactive, ->{ where("companies.deleted_at IS NOT NULL").order("companies.name ASC") }
  scope :for_user,  ->(user){
    case user.class.to_s
    when 'CustomersEmployee'
      where("companies.id = ?", user.id)
    when 'Trucker'
      where("companies.id = ?", user.id)
    when 'SuperAdmin', 'Admin'
      all
    else
      raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :for_role, ->(role){
    joins(:roles).where("lower(roles.name) = ?", role.to_s)
  }

  before_save :encrypt_password, if: Proc.new{|user| user.password.present?}
  after_save  :set_pwd_inited

  SET_PASSWORD_REQUEST_APPROVED = "Check your email to set password."
  UNAVAILABLE_EMAIL = "Sorry! We can't find this email in the system."
  UNAVAILABLE_CODE  = "Sorry! You are not allowed to set password. Please go to home page to request again."
  SET_PASSWORD_SUCCESS = "Congratulations! Your password has been successfully reset!"
  COMBINATION_ERROR  = "Sorry! The name and email combination does not exist."
  TRY_NEW_EMAIL = "Sorry! That email already exists in the system. Please try another new email."
  RESET_EMAIL_SUCCESS = "Congratulations! Your email has been successfully reset!"

  def icon
    "fa fa-user"
  end

  def name_with_role
    "#{type}: #{name}"
  end

  def email_with_name
    "#{self.name} <#{self.email}>"
  end

  def change_pwd
     @change_pwd
  end

  def change_pwd=(form_attribute)
    @change_pwd = (form_attribute == "1") ? true : false
  end

  def has_role?(*symbols)
    roles.where("name IN (?)", symbols.map(&:to_s).map(&:titleize)).exists?
  end

  def has_access?(controller, action)
    Right.joins(:roles).exists?(controller: controller, action: action, rights_roles: { role_id: role_ids })
  end

  def self.authenticate(email, password)
    user = find_by(email: email, deleted_at: nil)
    return nil if user.nil?
    return user if user.authenticated?(password)
  end

  def self.auth_by_token(token)
    token.blank? ? nil : find_by(mobile_token: token)
  end

  def pwd_inited?
    encrypted_password.present?
  end

  def authenticated?(password)
    encrypted_password == encrypt(password)
  end

  def self.login(email, password, request)
    User.http_request = request
    if user = authenticate(email, password)
      User.authenticated_user = user
      user.tried_to_login = true
      user.failed_login_attempts = 0
      user.logins += 1
      user.save
      return user
    elsif user = find_by(email: email)
      user.tried_to_login = true
      user.failed_login_attempts += 1
      user.save
      return false
    end
  end

  def try_to_login(request)
    self.class.login(self.email, self.password, request)
  end

  def self.from_cookie(cookies)
    unless cookies[:auth_token].blank?
      user = User.find_by(remember_token: cookies[:auth_token])
      user if user&&user.remember_token?
    end
  end

  def valid_token?(cookie)
    (self.remember_token==cookie[:auth_token])&&remember_token?
  end

  def remember_token?
    (!self.remember_token.blank?)&&self.remember_token_expires_at&&(Time.now < self.remember_token_expires_at)
  end

  def remember_me(expires_at=2.weeks.from_now)
    self.remember_token = make_token
    self.remember_token_expires_at = expires_at
    self.save(validate: false)
  end

  def refresh_token
    self.remember_token = make_token
    self.save(validate: false)
  end

  def forget_me
    self.remember_token = nil
    self.remember_token_expires_at = nil
    self.save(validate: false)
  end

  def self.restore_session(user_id, request)
    User.http_request = request
    User.authenticated_user = find_by(id: user_id)
  end

  def self.authenticated_user=(user)
    RequestStore.store[:authenticated_user] = user
  end

  def self.authenticated_user
    RequestStore.store[:authenticated_user]
  end

  def self.http_request=(request)
    RequestStore.store[:http_request] = request
  end

  def self.http_request
    RequestStore.store[:http_request]
  end

  def is_user?
    true
  end

  def email_to_reset?
    User.where(email: self.email, deleted_at: nil).count > 1
  end

  def self.reset_email(name, old_email, new_email)
    return COMBINATION_ERROR if name.blank? || old_email.blank?
    user = User.find_by(name: name.strip, email: old_email.strip)
    return COMBINATION_ERROR if user.nil?
    return TRY_NEW_EMAIL if new_email.blank?
    return TRY_NEW_EMAIL if User.find_by(email: new_email.strip)
    user.email = new_email.strip
    return TRY_NEW_EMAIL unless user.save
    RESET_EMAIL_SUCCESS
  end

  def generate_uuid
    update_column(:uuid, SecureRandom.hex(6))
  end

  def request_init_password
    User.request_set_password(email: email)
  end

  def self.set_password(params, post=true)
    code = params[:code]
    return UNAVAILABLE_CODE if code.nil?
    begin
      user = User.find_by(uuid: code)
      raise UNAVAILABLE_CODE if user.nil?
      attrs = {
        uuid: nil, change_pwd: "1",
        password: params[:password],
        password_confirmation: params[:password_confirmation]
      }
      if user.partial_save(attrs)
        SET_PASSWORD_SUCCESS
      else
        raise user.errors.full_messages_for(:password_confirmation).join("; ")
      end
    rescue => ex
      ex.message.gsub(/.*:/,'').strip
    end if post
  end

  def self.request_set_password(options={})
    case true
    when options.has_key?(:email)
      build_secure_code(options[:email].strip)
    when options.has_key?(:code)
      verify_secure_code(options[:code].strip)
    else
      "Unkown Request"
    end
  end

  def self.build_secure_code(email)
    return UNAVAILABLE_EMAIL if email.blank?
    user = User.find_by(email: email)
    return UNAVAILABLE_EMAIL unless user
    user.generate_uuid
    user.reload
    UserMailer.delay.request_set_password(user.id)
    SET_PASSWORD_REQUEST_APPROVED
  end

  def self.verify_secure_code(code)
    return UNAVAILABLE_CODE if code.blank?
    user = User.find_by(uuid: code)
    user.nil? ? UNAVAILABLE_CODE : user
  end

  def refresh_mobile_token
    self.mobile_token = make_token
    self.save(validate: false)
  end

  def clear_mobile_token
    self.mobile_token = nil
    self.save(validate: false)
  end

  def register_device(uid)
    User.where(device_id: uid).update_all(device_id: nil)
    update_column(:device_id, uid)
  end

  # dependencies needed to load child classes so
  # when I do User.find(:id) it searches for Admin, CustomersEmployee and Trucker
  require_dependency 'admin'
  require_dependency 'trucker'
  require_dependency 'customers_employee'
  require_dependency 'crawler'

  private

    def make_token
      secure_hash(Time.now.to_s + "--" + (1..10).map{rand.to_s}.join(''))
    end

    def encrypt_password
      self.salt = make_salt
      self.encrypted_password = encrypt(password)
    end

    def encrypt(string)
      secure_hash("#{salt}--#{string}")
    end

    def make_salt
      secure_hash("#{SecureRandom.hex(16)}--#{password}")
    end

    def secure_hash(string)
      Digest::SHA2.hexdigest(string)
    end

    def set_pwd_inited
      if encrypted_password_was.blank? && encrypted_password_changed?
        update_column(:pwd_inited_date, Date.today)
      end
    end

end
