class Truck < ApplicationRecord
  attr_accessor :owner_id

  has_paper_trail ignore: [:created_at, :updated_at]

  belongs_to :trucker, ->{ unscope(where: :mark) }
  has_many :fuel_purchases
  has_many :daily_mileages
  has_many :images, as: :imagable, dependent: :destroy
  has_and_belongs_to_many :states, join_table: "states_trucks", foreign_key: :truck_id

  validates :number, presence: true, numericality: true
  validates :trucker_id, presence: true

  scope :as_default, ->{
    where(default: true)
  }

  after_create :set_default
  after_update :set_default
  after_destroy :set_default

  OWNERSHIP_TAG = 'ownership'

  def self.states
    State.search(:abbrev_not_in => %w{GU HI KY PW PR OU}).result
  end

  def name
    "#{trucker.name}-#{number}"
  end

  def last_quarterly_maintenance_report
    if self[:last_quarterly_maintenance_report].nil?
      nil
    else
      self[:last_quarterly_maintenance_report] + 120.days
    end
  end

  def optional_owners
    trucker.hub.truckers.where.not(id: trucker_id).active
  end

  def self.default(trucker)
    trucker.trucks.as_default.first
  end

  def siblings
    trucker.trucks.where("trucks.id <> ?", id)
  end

  def unset_previous_default
    siblings.map(&:unset_default)
  end

  def unset_default
    update_column(:default, false)
  end

  def set_default
    if default?
      unset_previous_default
      truck = persisted? ? self : trucker.trucks.first
    else
      truck = Truck.default(trucker) || trucker.trucks.first
    end
    truck.try(:update_column, :default, true)
  end

  def has_pending_approval_renew_doc?(type)
    images.pending.for_column(type.to_s).exists?
  end

  def assign!(owner_id)
    raise "You can't assign to the same one." if owner_id == trucker_id
    owner = optional_owners.find(owner_id)
    truck = self.dup
    truck.trucker = owner
    truck.default = true
    user = User.authenticated_user
    images.each do |image|
      next unless image.file_exists?
      truck.images.build(
        user: user,
        file: image.file,
        status: image.status,
        column_name: image.column_name
      )
    end
    truck.save!
    truck
  end

end
