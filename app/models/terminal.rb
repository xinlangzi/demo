class Terminal < Company
  include HubAssociation
  belongs_to_hub presence: true

  belongs_to :rail_road
  has_one :port, through: :rail_road
  has_many :operations, class_name: 'Operation', foreign_key: :company_id
  has_many :containers, through: :operations

  validates :name, uniqueness: { scope: [:deleted_at, :hub_id] }, unless: -> { Rails.env.test? }
  validates :address_city, presence: true
  validates :address_state_id, presence: true
  validates :phone, presence: true
  validates :rail_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :lat, :lng, :rail_road_id, presence: true

  validate do |terminal|
    errors.add(:name, "must be identical to its related railroad.") if terminal.rail_road.nil? || terminal.name != terminal.rail_road.name
  end

  scope :group_options, ->{ order('name ASC') }

  after_save :recalculate_miles
  before_destroy do
    throw :abort unless self.containers.blank?
  end

  def ophours?
    true
  end

end
