class Consignee < CustomersClient
  include HubAssociation
  belongs_to_hub presence: true
  has_many :operations, class_name: 'Operation', foreign_key: :company_id
  has_many :containers, through: :operations

  after_save :recalculate_miles
  before_destroy do
    throw :abort unless self.containers.blank?
  end

  def self.states(customer_id=nil)
    options = {}
    options[:customer_id_eq] = customer_id
    ids = Consignee.search(options).result.reorder('').select(:address_state_id).distinct
    states = State.where(id: ids).order("name ASC")
    states.map{|s| [s.name.strip, s.id]}
  end

  def self.cities(state_id=nil, customer_id=nil)
    options = {}
    options[:customer_id_eq] = customer_id
    options[:address_state_id_eq] = state_id
    cities = Consignee.search(options).result.reorder('').select(:address_city).distinct
    cities.map{|c| c.address_city.strip}.sort
  end
end
