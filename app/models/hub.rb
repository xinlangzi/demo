class Hub < ApplicationRecord
  acts_as_paranoid
  has_many :containers, dependent: :restrict_with_exception
  has_many :companies, dependent: :restrict_with_exception
  has_many :consignees, dependent: :restrict_with_exception
  has_many :depots, dependent: :restrict_with_exception
  has_many :shippers, dependent: :restrict_with_exception
  has_many :terminals, dependent: :restrict_with_exception
  has_many :truckers, dependent: :restrict_with_exception
  has_many :yards, dependent: :restrict_with_exception
  has_many :ports, dependent: :restrict_with_exception
  has_many :fuels, dependent: :restrict_with_exception
  has_many :mile_rates, dependent: :restrict_with_exception
  has_many :customer_rates, dependent: :restrict_with_exception
  has_many :driver_rates, dependent: :restrict_with_exception
  has_many :customer_drop_rates, dependent: :restrict_with_exception
  has_many :driver_drop_rates, dependent: :restrict_with_exception
  has_many :spot_quotes, dependent: :nullify

  has_many :hub_interchanges, dependent: :destroy

  accepts_nested_attributes_for :hub_interchanges,  allow_destroy: true

  validates :name, presence: true, uniqueness: { case_sensitive: false }
  validates :fuel_zone, presence: true

  scope :with_default, ->{ where("demo IS NOT TRUE") }

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin', 'CustomersEmployee'
      all
    when 'Admin'
      user.hubs
    when 'Trucker'
      where(id: user.hub_id)
    else
      none
    end
  }

  def active_truckers
    truckers.active
  end

  def self.default(user)
    case user.class.to_s
    when 'SuperAdmin', 'CustomersEmployee'
      Hub.first
    when 'Admin'
      user.hubs.first
    when 'Trucker'
      user.hub
    else
      nil
    end
  end

  def to_s
    name.try(:downcase)
  end

  def self.demo
    unscoped.where(demo: true).first_or_initialize(name: "Demo") do |hub|
      hub.save(validate: false)
    end
  end
end