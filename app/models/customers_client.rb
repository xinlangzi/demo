class CustomersClient < Company

  DEFAULT_CITY_FIELD = 'Enter city'
  DEFAULT_SHIPPER_FIELD = 'Enter Shipper'
  DEFAULT_CONSIGNEE_FIELD = 'Enter Consignee'

  validates_presence_of :customer_id
  belongs_to :customer
  validates :name, uniqueness: {scope: [:deleted_at, :customer_id], case_sensitive: false }
  validates :address_state_id, presence: true
  validates :address_city, presence: true
  validates :phone, presence: true
  validates :lat, :lng, presence: true

  scope :for_user, ->(user){
      case user.class.to_s
      when 'CustomersEmployee'
        where(customer_id: user.customer.id)
      when 'Customer'
        where(customer_id: user.id)
      when 'SuperAdmin', 'Admin'
        all
      else raise "Authentication / Access error for #{user.class}"
      end
  }
  scope :active, ->{ where('companies.deleted_at IS NULL') }
  scope :within_state, ->(state_id){ where(address_state_id: state_id) if state_id }


  def self.get_cities_and_states
    where.not(deleted_at: nil).collect {|s| [s.address_city, s.address_state.abbrev, s.id] }
  end

  def self.autocomplete(hub, company, name, city, state, order_by="companies.name ASC")
    name.strip!
    city.strip!
    name = nil if [DEFAULT_CONSIGNEE_FIELD, DEFAULT_SHIPPER_FIELD].include?(name)
    city = nil if city == DEFAULT_CITY_FIELD
    options = { name_cont: name, address_city_cont: city, address_state_id_eq: state }
    self.active.for_user(company).for_hub(hub).order(order_by).search(options).result
  end

  # These two babies have to be down here
  require_dependency 'consignee'
  require_dependency 'shipper'

end
