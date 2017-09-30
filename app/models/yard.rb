class Yard < Company
  include HubAssociation
  belongs_to_hub presence: true
  has_many :operations, class_name: 'Operation', foreign_key: :company_id
  has_many :containers, through: :operations



  validates :phone, presence: true
  validates :address_city, presence: true
  validates :address_state_id, presence: true
  validates :name, uniqueness: { scope: :deleted_at }
  validates :lat, :lng, presence: true

  scope :group_options, ->{ order('name ASC') }

  after_save :recalculate_miles
  before_destroy do
    throw :abort unless self.containers.blank?
  end

  def ophours?
    true
  end
end