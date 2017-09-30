class CustomerRate < ApplicationRecord
  include BaseRate
  include HubAssociation
  belongs_to_hub presence: true

  validates :rate, :fuel_ratio, presence: true
  validates :miles, :rate, :fuel_ratio, numericality: { greater_than: 0}

  before_save :build_gallons

  scope :editable, ->{ where("miles > 0") }

  def fuel_amount
    (rate*fuel_ratio/100.0).round(2) rescue ''
  end

  def actual_fuel_amount
    [0, (Fuel.latest_price(hub)*self.gallons - basic_fuel_fee).round(2)].max
  end

  # calculate how many gallons needs for x miles base on fuel price($3.5 per gallon)
  def build_gallons
    self.gallons||= ((self.fuel_amount + self.basic_fuel_fee)/3.5).round(2)
  end

  # fuel fee when $2 per gallon
  def basic_fuel_fee
    (mile_rate.key_fuel_price * (_miles/mile_rate.avg_mpg)).round(2)
  end

  def _miles
    self.miles > 0 ? self.miles : CustomerRate.for_hub(hub).where("miles != 0").first.miles
  end

  def mile_rate
    @mile_rate||= MileRate.default(hub)
  end

end
