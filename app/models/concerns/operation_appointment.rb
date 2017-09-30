module OperationAppointment
  extend ActiveSupport::Concern

  included do

    scope :appt_miles_status, ->{
      # ontime: 0: late, 1: ontime
      select("operations.trucker_id,
              operations.container_id,
              companies.name AS trucker_name,
              MAX(IF(delay_by_trucker, IFNULL(delay_mins, 0), 0)) AS delay_mins,
              MIN(IF(IFNULL(appt_status, 1) = 0, IF(delay_by_trucker, 0, 1), 1)) AS ontime,
              SUM(complete_mileage) AS miles").
      joins(:trucker).
      group("trucker_id, container_id").
      order("companies.name ASC")
    }
  end

  module ClassMethods

    def init_delay_by_trucker(scoped)
      scoped.where(delay_by_trucker: nil).update_all(delay_by_trucker: true)
    end

    def move_stats(scoped)
      init_delay_by_trucker(scoped)
      summary = {}
      scoped.appt_miles_status.as_json.group_by(&:trucker_id).each do |trucker_id, items|
        trucker_name = items.first.trucker_name
        delay_mins = items.sum(&:delay_mins)
        trips = items.map(&:miles)
        ontimes = items.map(&:ontime)
        summary[trucker_id] = {
          trucker_id: trucker_id,
          trucker_name: trucker_name,
          moves: ontimes.size,
          under50mi: trips.count{|miles| miles < 50 },
          over50mi: trips.count{|miles| miles >= 50 },
          lates: ontimes.count(0),
          ontimes: ontimes.count(1),
          late_ratio: Rational(ontimes.count(0), ontimes.size).to_f,
          ontime_ratio: Rational(ontimes.count(1), ontimes.size).to_f,
          delay_mins: delay_mins
        }
      end
      summary
    end

    def to_late_appointments_csv(summary)
      CSV.generate do |csv|
        csv << [
          "Driver",
          "Moves",
          "<50 miles",
          ">=50 miles",
          "Lates",
          "Late Rate"
        ]

        summary.each do |id, info|
          csv << [
            info[:trucker_name],
            info[:moves],
            info[:under50mi],
            info[:over50mi],
            info[:lates],
            "#{(info[:late_ratio]*100).round(2)}%"
          ]
        end
      end
    end

  end
end
