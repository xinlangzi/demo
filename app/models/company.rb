class Company < ApplicationRecord

  ONLY_TRAIL_ATTRIBUTES = [
    :accounting_email, :acct_only, :address_city, :address_country, :address_state_id, :address_street, :address_street_2,
    :billing_city, :billing_country, :billing_state_id, :billing_street, :billing_street_2, :billing_zip_code,
    :chassis_fee, :check_missing_doc, :collection_email, :comments, :contact_person, :customer_id,
    :date_of_birth, :deleted_at, :device_id, :dl_expiration_date, :dl_haz_endorsement, :dl_no, :dl_state_id,
    :driver_docusign_envelope_id, :driver_type,
    :edi_customer_code, :edi_provider_id, :email, :eq_team_email, :extra_contact_info,
    :fax, :fein, :for_container,
    :hire_date, :hub_id,
    :inactived_at, :invoice_j1s,
    :mark, :medical_card_expiration_date, :name,
    :onfile1099, :ophours,
    :phone, :phone_extension, :phone_mobile,
    :print_name, :pwd_inited_date,
    :quickbooks_integration,
    :rail_billing_email, :rail_fee, :rail_road_id,
    :ssline_id, :ssn,
    :termination_date, :trucker_id,
    :use_edi,
    :web, :week_pay,
    :zip_code
  ].freeze

  PAPER_TRAIL_TRANSLATION ={
    "customer_id"           => ->(id){ Customer.find(id).to_s },
    "address_state_id"      => ->(id){ State.find(id).to_s },
    "billing_state_id"      => ->(id){ State.find(id).to_s },
    "dl_state_id"           => ->(id){ State.find(id).to_s },
    "hub_id"                => ->(id){ Hub.find(id).to_s },
    "rail_road_id"          => ->(id){ RailRoad.find(id).to_s },
    "trucker_id"            => ->(id){ Trucker.find(id).to_s },
    "ssline_id"             => ->(id){ Ssline.find(id).to_s }
  }.freeze

  has_paper_trail only: ONLY_TRAIL_ATTRIBUTES, unless: Proc.new{ Rails.env.test? }

  NEED_ADMIN_APPROVAL = ['Trucker', 'Admin', 'CustomersEmployee']

  belongs_to :address_state, class_name: 'State', foreign_key: 'address_state_id'
  belongs_to :billing_state, class_name: 'State', foreign_key: 'billing_state_id'
  belongs_to :admin
  has_many :discounts, ->{ order('created_at DESC') }
  has_many :invoices
  has_many :payable_invoices, class_name: 'PayableInvoice'
  has_many :receivable_invoices, class_name: 'ReceivableInvoice'
  has_many :operations
  has_many :container_charges
  has_many :locations, dependent: :destroy

  validates :name, presence: true
  validates :email, multiple_email: true, unless: Proc.new{|user| ["Admin", "CustomersEmployee", "SuperAdmin", "Trucker", "Owner"].include?(user.type) }
  validates :lat, numericality: true, allow_nil: true
  validates :lng, numericality: true, allow_nil: true
  validates :phone, format: { with: /\A\(?\d{3}[) ]?\s?\d{3}[- ]?\d{4}\Z/i, multiline: true, message: "Must be like (123) 456-7890 or 123 456 7890." }, allow_blank: true, allow_nil: true
  validates :phone_mobile, format: { with: /\A\(?\d{3}[) ]?\s?\d{3}[- ]?\d{4}\Z/i, multiline: true, message: "Must be like (123) 456-7890 or 123 456 7890." }, allow_blank: true, allow_nil: true
  validates :phone_extension, length: { maximum: 7 }
  validates_numericality_of :chassis_fee, allow_nil: true, :greater_than_or_equal_to => 0

  with_options multiple_email: true do |company|
    company.validates :accounting_email
    company.validates :collection_email
  end


  with_options timeliness: { type: :date }, format: /\A\d{4}-\d{2}-\d{2}\Z/, allow_nil: true, allow_blank: true do |company|
    company.validates :date_of_birth
    company.validates :dl_expiration_date
    company.validates :hire_date
    company.validates :medical_card_expiration_date
    company.validates :termination_date
  end

  scope :incomplete_address, ->{ where("IFNULL(lat, 0) = 0 OR IFNULL(lng, 0) = 0") }
  scope :active, ->{ where("companies.deleted_at IS NULL") }
  scope :deleted, ->{ where("companies.deleted_at IS NOT NULL") }
  scope :other, ->{ where("type NOT IN (?)", %w(Trucker Customer Accounting::TpVendor Accounting::TpCustomer)) }
  scope :third_party, ->{ where("type IN (?)", %w(Accounting::TpCustomer Accounting::TpVendor))}
  scope :uninvoiced, ->(accounts){ where(id: ContainerCharge.uninvoiced_companies_id(accounts)) }
  scope :invoiced,   ->(accounts){ where(id: ContainerInvoice.invoiced_companies_id(accounts)) }
  scope :outstanding,->(accounts){ where(id: ContainerInvoice.outstanding_companies_id(accounts)) }
  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin', 'Admin'
      all
    when 'CustomersEmployee'
      where('companies.id = ?', user.customer.id)
    when 'Trucker'
      where('companies.id = ?', user.id)
    else
      raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :for_hub, ->(hub){
    where(hub_id: hub.id)
  }

  scope :viewable_by, ->(user){
    case user.class.to_s
    when 'SuperAdmin'
    when 'Admin'
    when 'CustomersEmployee'
      where("customer_id = ?", user.customer_id)
    when 'Trucker'
      limit(0)
    end
  }

  scope :match_customers, ->(emails){
    emails = Array(emails).map(&:downcase)
    where("lower(companies.email) IN (?)", emails).
    where("companies.type IN (?)", ['Customer', 'CustomersEmployee']).
    order('type asc, id asc')
  }

  scope :exact_address_match, lambda { |zip, state, city, address|
    {
      :conditions => [
        "companies.zip_code = ? AND LOWER(companies.address_city) = ? AND LOWER(companies.address_street) = ? AND LOWER(companies.address_street_2) = ? AND LOWER(states.abbrev) = ?",
        zip,
        city.downcase,
        address.first.downcase,
        address.last.downcase,
        state.downcase
      ],
      :joins => :address_state
    }
  }

  default_scope { order("companies.name ASC") }

  after_save :address_valid?

  delegate :abbrev, to: :address_state

  # We redefine these is_* methods in child classes

  def split_email(method)
    send(method).to_s.split(/,|;/).map(&:strip)
  end

  def active?
    deleted_at.nil?
  end

  def inactive?
    !active?
  end

  def is_user?
    false
  end

  def is_admin?
     false
  end

  def is_superadmin?
    false
  end

  def is_customer?
    false
  end

  def is_trucker?
    false
  end

  def is_ssline?
    false
  end

  def to_s
    name
  end
###Add url value to json_for_autocomplete hash
  def url
    "/#{self.class.to_s.pluralize.underscore}/#{self.id}"
  end

  def icon
    "fa fa-building-o"
  end

  def self.get_names_and_ids
    active.collect {|s| [s.name, s.id] }
  end

  def self.get_all_names_and_ids
    self.all.collect{|s| [s.name, s.id] }
  end

  def active_status
    self.active? ? "Active" : "Inactive"
  end

  def self.group_by_status
    self.all.collect{|s| [s.active_status, s.name, s.id] }.group_by{|x| x.delete_at(0)}
  end

  def latest_discount
    self.discounts.first
  end

  def state
    address_state.try(:abbrev)
  end

  def deleted?
    deleted_at?
  end

  def mark_as_deleted
    update_column(:deleted_at, Time.now)
    touch
  end

  def lat_lng
    [lat, lng].compact.join(",")
  end

  def address_streets
    [address_street, address_street_2].compact.join(" ").strip
  end

  def address
    "#{self.address_street}, #{self.address_city}, #{self.state} #{self.zip_code}"
  end

  def city_state_zip
    "#{self.address_city}, #{self.state} #{self.zip_code}"
  end

  def billing_streets
    [billing_street, billing_street_2].compact.join(" ").strip
  end

  def billing_address
    "#{self.billing_street}, #{self.billing_city}, #{self.billing_state} #{self.billing_zip_code}"
  end

  def billing_city_state_zip
    "#{self.billing_city}, #{self.billing_state} #{self.billing_zip_code}"
  end

  def charges
    Charge.where(company_id: self.id)
  end

  def self.match_customer(emails)
    match_customers(emails).collect{|m| m.is_a?(CustomersEmployee) ? m.customer : m}.compact.first
  end

  def address_valid?
    if [Consignee, Depot, Shipper, Terminal].include?(self.class)
      if self.lat.to_i == 0 || self.lng.to_i == 0
        MyMailer.delay.invalid_address(id)
      end
    end unless Rails.env.test? # save spec time
  end

  def recalculate_miles
    if lat_changed? or lng_changed?
      related_ids = []
      containers.unlocked.distinct.each do |container|
        unless container.payable_invoiced?
          related_ids << container.id
          container.send(:build_scheduled_trips)
        end
      end
      Notification.create(
        category: :mileages_updated,
        detail: "The address of #{name} is updated. The mileages will be updated soon. Please pay attention to the accts. payable on the containers: #{related_ids.join(", ")}."
      ) if related_ids.present?
    end
  end

  def ophours?
    false
  end

  def send_invoice_by_edi?
    false
  end

  def invoice_footer
  end

  def self.csv(companies, procs={})
    CSV.generate do |csv|
      csv << procs.keys
      methods = procs.values
      companies.each do |company|
        csv << methods.map{|method| company.send(:eval, method) }
      end
    end
  end

  alias_method :really_destroy, :destroy

  def destroy
    if containers.empty?&&invoices.empty?
      really_destroy
    else
      mark_as_deleted
    end
  end

  require_dependency 'user'
  require_dependency 'customers_client'
  require_dependency 'depot'
  require_dependency 'ssline'
  require_dependency 'terminal'
  require_dependency 'owner'
  require_dependency 'customer'

end
