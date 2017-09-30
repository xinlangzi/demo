class FuelPurchase < ApplicationRecord
  paginates_per 20

  belongs_to :trucker
  belongs_to :truck
  belongs_to :purchase_state, class_name: 'State', foreign_key: :purchase_state_id
  has_many :images, as: :imagable, dependent: :destroy

  validates :day, :price, :gallons, :purchase_state_id, :trucker_id, :truck_id, presence: true
  validates :price, :gallons, numericality: true

  attr_accessor :file, :user_id

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin', 'Admin'
      all
    when 'Trucker'
      where(trucker_id: user.id)
    else raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :for_hub, ->(hub){
    joins(:trucker).where("companies.hub_id = ?", hub.id)
  }

  delegate :name, to: :trucker

  after_save :store_receipt

  def receipt
    images.first
  end

  def related_trucks
    trucker.trucks rescue []
  end

  ### instant set ########
  def set_trucker(id)
    self.trucker_id = id
    set_default_truck(trucker)
  end

  def set_default_truck(trucker)
    self.truck = Truck.default(trucker)
  end

  def amount
    gallons * price
  end

  def self.total_gallons(fuel)
    fuel.inject(0){|sum, fp| sum + fp.gallons }
  end

  def self.total_amount(fuel)
    fuel.inject(0){|sum, fp| sum + fp.amount }
  end


  def self.truckers
    Trucker.joins(:fuel_purchases).distinct
  end

  def self.quarterly(year, quarter, trucker)
    between_dates = DailyMileage.quarterly_dates(year, quarter)
    if trucker
      FuelPurchase.where("day <= ? AND day >= ? AND trucker_id = ?", between_dates.last, between_dates.first, trucker.id)
    else
      FuelPurchase.where("day <= ? AND day >= ?", between_dates.last, between_dates.first)
    end
  end

  def self.years(trucker)
    if trucker
      min = FuelPurchase.where('trucker_id = ?', trucker.id).minimum(:day)
      max = FuelPurchase.where('trucker_id = ?', trucker.id).maximum(:day)
    else
      min = FuelPurchase.minimum(:day)
      max = FuelPurchase.maximum(:day)
    end
    (min.year..max.year).to_a rescue []
  end

  private
  def store_receipt
    if file.present?
      Image.build(imagable: self, column_name: 'id') do |image|
        image.file = file
        image.user_id = user_id
      end
    end
  end
end
