class StateMileage < ApplicationRecord

  belongs_to :daily_mileage
  belongs_to :state, class_name: 'State', foreign_key: 'state_id'

  validates :miles, numericality: true
  validates :state_id, presence: true

  # returns an array of new StateMileage objects, with the attrs state and miles set
  def self.quarterly(year, quarter, trucker)
    between = DailyMileage.quarterly_dates(year, quarter)
    if trucker
      state_miles = StateMileage.joins(daily_mileage: :truck).
                                  where("day >= ? AND day <= ? AND trucker_id = ?", between.first, between.last, trucker.id).
                                  group("state_id").
                                  select("state_id, SUM(miles) AS miles")
    else
      state_miles = StateMileage.joins(:daily_mileage).
                                  where("day >= ? AND day <= ?", between.first, between.last).
                                  group("state_id").
                                  select("state_id, SUM(miles) AS miles")
    end
    state_miles.map do |sm|
      StateMileage.new(state_id: sm.state_id, miles: sm.miles)
    end
  end

end
