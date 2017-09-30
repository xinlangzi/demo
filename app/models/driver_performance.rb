class DriverPerformance

  POINTS_CC    = 0.4
  LATES_CC     = 0.17
  WORKS_CC     = 0.12
  CANCELS_CC   = 0.22
  UNDER50MI_CC = 0.03
  OVER50MI_CC  = 0.06

  class DriverFactor < Struct.new(
      :trucker,
      :points, :weekdays, :vacations, :dispatched, :undispatched, :worked_ratio,
      :moves, :under50mi, :over50mi, :lates, :ontimes, :late_ratio, :ontime_ratio, :delay_mins,
      :cancels, :score
    )

    def initialize(options={})
      options.each do |key, value|
        self.send("#{key}=", value) if respond_to?(key)
      end
      members.each do |member|
        self.send("#{member}=", 0) unless self.send(member)
      end
    end

    def avg_point
      DriverPerformance.rational(points, weekdays)
    end

    def avg_delay_mins
      DriverPerformance.rational(delay_mins, moves)
    end

    def avg_under50mi
      DriverPerformance.rational(under50mi, dispatched)
    end

    def avg_over50mi
      DriverPerformance.rational(over50mi, dispatched)
    end

  end

  def self.rational(a, b)
    Rational(a, b).to_f rescue 0
  end

  def self.evaluation(from, to)
    filter = DriverPerformanceFilter.new({ from: from, to: to })
    truckers = Trucker.hired
    operations = Operation.search(filter.actual_appt_range).result.where(trucker: truckers)
    move_stats = Operation.move_stats(operations)
    work_stats = Trucker.work_stats(truckers, filter.from, filter.to)
    cancelled_stats = CancelledAppointment.unscoped.search(filter.cancelled_appt_range).result.group(:trucker_id).count

    driver_factors = truckers.map do |trucker|
      cancels = cancelled_stats[trucker.id]
      options = { trucker: trucker, cancels: cancels }
      options.merge!(work_stats[trucker.id] || {})
      options.merge!(move_stats[trucker.id] || {})
      DriverFactor.new(options)
    end

    max_avg_point = driver_factors.map(&:avg_point).max
    max_avg_delay_mins = driver_factors.map(&:avg_delay_mins).max
    max_worked_ratio = driver_factors.map(&:worked_ratio).max
    max_cancels = driver_factors.map(&:cancels).max
    max_avg_under50mi = driver_factors.map(&:avg_under50mi).max
    max_avg_over50mi = driver_factors.map(&:avg_over50mi).max

    driver_factors.each do |factor|
      factor.score = 0
      if factor.moves > 0
        factor.score+= (1 - rational(factor.avg_point, max_avg_point))*POINTS_CC
        factor.score+= (1 - rational(factor.avg_delay_mins, max_avg_delay_mins))*LATES_CC
        factor.score+= rational(factor.worked_ratio, max_worked_ratio)*WORKS_CC
        factor.score+= (1 - rational(factor.cancels, max_cancels))*CANCELS_CC
        factor.score+= rational(factor.avg_under50mi, max_avg_under50mi)*UNDER50MI_CC
        factor.score+= rational(factor.avg_over50mi, max_avg_over50mi)*UNDER50MI_CC
        factor.score = factor.score.round(2)
      end
    end
    driver_factors
  end

  def self.scores
    from = Date.today.beginning_of_week(:sunday) - 6.months
    to = Date.today.beginning_of_week(:sunday)
    Rails.cache.read(:driver_scores) || {}.tap do |summary|
      evaluation(from, to).each do |factor|
        summary[factor.trucker.id] = factor.score
      end
      Rails.cache.write(:driver_scores, summary, expires_in: 1.day)
    end
  end

end
