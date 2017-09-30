class AvailStats

  def self.summary(hub, from=Date.today, to=(Date.today + 13.days))
    summary = trucker_stats(hub, from, to)
    assigned_factors = assigned_weight_factors(hub, from, to)
    unassigned_factors = unassigned_weight_factors(hub, from.prior_business_day(1), to.prior_business_day(1))
    dropped_factors = dropped_without_appt_weight_factors(hub, from.prior_business_day(3), to.prior_business_day(3))
    prealert_factors = prealerts_weight_factors(hub, from.prior_business_day(1), to.prior_business_day(1))
    additional_factors = 0
    summary.each do |date, stats|
      factors = stats[:available]
      date = date.to_date
      factors-= additional_factors
      factors-= assigned_factors[date.ymd].to_f
      factors-= date.weekend? ? 0 : unassigned_factors[date.prior_business_day(1).ymd].to_f
      factors-= date.weekend? ? 0 : dropped_factors[date.prior_business_day(3).ymd].to_f
      factors-= date.weekend? ? 0 : prealert_piror_dates(date).map{|date| prealert_factors[date.ymd].to_f }.sum
      # puts "A: #{additional_factors} A:#{assigned_factors[date.ymd].to_f} U:#{unassigned_factors[(date.prior_business_day(1)).ymd].to_f} D:#{dropped_factors[(date.prior_business_day(3)).ymd].to_f} P:#{prealert_factors[(date.prior_business_day(1)).ymd].to_f}"
      if factors < 0
        summary[date.ymd][:available] = 0
        additional_factors = factors.abs
      else
        summary[date.ymd][:available] = factors
        additional_factors = 0
      end
      # puts "#{date} : #{summary[date.ymd][:available]}"
    end
    summary
  end

  def self.trucker_stats(hub, from, to)
    trucker_stats = {}
    sql = Sqls::Template::TRUCKER_VACATION_STATS%{hub_id: hub.id, start: from.ymd, end: to.ymd}
    Sqls::Template.run(sql).group_by(&:date).each do |date, rows|
      rows.delete_if{|row| row.id.nil?}
      trucker_stats[date] = { total: rows.size }
      if date.to_date.weekend? || Holiday.include?(date.to_date)
        trucker_stats[date][:available] = 0
      else
        trucker_stats[date][:available] = rows.map(&:weight_factor).map{|weight_factor| weight_factor.nil? ? 1 : weight_factor}.sum.to_f
      end
    end
    trucker_stats
  end

  def self.summary_by_date(tmpl, hub, from, to)
    summary_by_date = {}
    group_containers_by_date(tmpl, hub, from, to).each do |date, rows|
      rows.delete_if{|row| row.container_id.nil?}
      summary_by_date[date] = rows.map(&:miles).map(&:weight_factor).sum
    end
    summary_by_date
  end

  def self.group_containers_by_date(tmpl, hub, from, to)
    sql = tmpl%{:hub_id => hub.id, :start => from.ymd, :end => to.ymd}
    Sqls::Template.run(sql).group_by(&:date)
  end

  def self.assigned_weight_factors(hub, from, to)
    summary_by_date(Sqls::Template::ASSIGNED_MILES_STATS, hub, from, to)
  end

  def self.unassigned_weight_factors(hub, from, to)
    summary_by_date(Sqls::Template::UNASSIGNED_MILES_STATS, hub, from, to)
  end

  def self.dropped_without_appt_weight_factors(hub, from, to)
    summary_by_date(Sqls::Template::DROPPED_WITHOUT_APPT, hub, from, to)
  end

  def self.prealerts_weight_factors(hub, from, to)
    summary_by_date(Sqls::Template::PREALERT_WITH_ETA, hub, from, to)
  end

  def self.assigned_containers(hub, from, to)
    group_containers_by_date(Sqls::Template::ASSIGNED_MILES_STATS, hub, from, to)
  end

  def self.unassigned_containers(hub, from, to)
    group_containers_by_date(Sqls::Template::UNASSIGNED_MILES_STATS, hub, from, to)
  end

  def self.dropped_without_appt_containers(hub, from, to)
    group_containers_by_date(Sqls::Template::DROPPED_WITHOUT_APPT, hub, from, to)
  end

  def self.prealerts_containers(hub, from, to)
    group_containers_by_date(Sqls::Template::PREALERT_WITH_ETA, hub, from, to)
  end

  def self.appt_range(hub)
    data = AvailStats.summary(hub)
    { from: data.keys.first, to: data.keys.last, disabled: data.keep_if{|k, v| v.available <= 3 }.keys }
  end

  def self.prealert_piror_dates(date)
    case true
    when date.monday? # summary last Fri & Sat
      [date.prior_business_day(1), date.ago(2.days)]
    when date.tuesday?# summary last Sun & Mon
      [date.ago(2.days), date.prior_business_day(1)]
    else
      [date.prior_business_day(1)]
    end
  end

  def self.adjust_avail(date, avail)
    if date.to_date <= Date.today.tomorrow
      avail <= 3 ? 0 : avail
    else
      avail
    end
  end

end