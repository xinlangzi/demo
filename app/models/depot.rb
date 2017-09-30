class Depot < Company
  include HubAssociation
  belongs_to_hub presence: true
  belongs_to :ssline
  has_many :operations, class_name: 'Operation', foreign_key: :company_id
  has_many :containers, through: :operations

  validates :name, presence: true
  validates :name, uniqueness: { scope: [:deleted_at, :ssline_id], case_sensitive: false }
  validates :address_city, presence: true
  validates :address_state_id, presence: true
  validates :ssline_id, presence: true
  validates :lat, :lng, presence: true

  after_save :recalculate_miles
  before_destroy do
    throw :abort unless self.containers.blank?
  end

  def self.states(ssline_id=nil)
    options = {}
    options[:ssline_id_eq] = ssline_id
    ids = Depot.search(options).result.reorder('').select(:address_state_id).distinct
    states = State.where(id: ids).order("name ASC")
    states.map{|s| [s.name.strip, s.id]}
  end

  def self.cities(state_id=nil, ssline_id=nil)
    options = {}
    options[:address_state_id_eq] = state_id if state_id
    options[:ssline_id_eq] = ssline_id if ssline_id
    cities = Depot.search(options).result.reorder('').select(:address_city).distinct
    cities.map{|c| c.address_city.strip}.sort
  end

  def ophours?
    true
  end

end
