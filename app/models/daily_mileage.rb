class DailyMileage < ApplicationRecord
  paginates_per 10

  attr_accessor :trucker_id

  belongs_to :truck
  has_many :state_mileages, dependent: :destroy

  accepts_nested_attributes_for :state_mileages, allow_destroy: true

  validates :start, :end,  presence: { message: ": Odometer reading can't be blank" }
  validates :day, :truck_id, presence: true
  validates :day, uniqueness: { scope: :truck_id, message: ": One recording per day allowed" }
  validates_associated :state_mileages

  validate do
    errors.add(:base, "Computed miles per state don't match total driven miles.") if computed_miles != self.mileage
    errors.add(:base, "Add states and miles") if state_mileages.reject(&:_destroy).blank?
    errors.add(:end, " mileage cannot be less than starting mileage.") if self.end.to_f <= self.start.to_f
  end

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin', 'Admin'
      all
    when 'Trucker'
      joins(truck: :trucker).where('companies.id = ?', user.id)
    else
      raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :for_hub, ->(hub){
    joins(truck: :trucker).
    where("companies.hub_id = ?", hub.id)
  }

  QUARTERS = {
    "1" => ["January 1st", "March 31st"],
    "2" => ["April 1st", "June 30th"],
    "3" => ["July 1st", "September 30th"],
    "4" => ["October 1st", "December 31st"]
  }.freeze

  def mileage
    self.end.to_f - self.start.to_f
  end

  def computed_miles
    state_mileages.reject(&:_destroy).map(&:miles).compact.sum
  end

  def trucker
    Trucker.find_by(id: trucker_id) || truck.try(:trucker)
  end

  def related_trucks
    trucker.trucks rescue []
  end

  ### instant set ########
  def set_trucker(id)
    self.trucker_id = id
    set_default_truck(trucker)
    set_start_mileage(truck)
  end

  def set_default_truck(trucker)
    self.truck = Truck.default(trucker)
  end

  # the function set start mileage for default truck only
  def set_start_mileage(truck)
    last_daily_mileage = DailyMileage.where(truck_id: truck.id).last if truck
    self.start = last_daily_mileage ? last_daily_mileage.end : BigDecimal("0")
  end

  def self.truckers
    Trucker.joins(trucks: :daily_mileages).distinct
  end

  def self.years(trucker)
    if trucker
      min = DailyMileage.joins(:truck).where('trucks.trucker_id = ?', trucker.id).minimum(:day)
      max = DailyMileage.joins(:truck).where('trucks.trucker_id = ?', trucker.id).maximum(:day)
    else
      min = DailyMileage.minimum(:day)
      max = DailyMileage.maximum(:day)
    end
    (min.year..max.year).to_a rescue []
  end

  # Returns an array with 2 elements: starting and ending dates of a quarter (1, 2, 3, or 4)
  def self.quarterly_dates(year, quarter)
    [(year + QUARTERS[quarter].first).to_date, (year + QUARTERS[quarter].last).to_date]
  end

end
