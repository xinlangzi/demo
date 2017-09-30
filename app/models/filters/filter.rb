class Filter < Tableless

  attr_accessor *%w{
    from
    to
    company_id
    trucker_id
    customer_id
    tp_company_id
    container_no
  }

  def sql_conditions(scoped)
  end

  def self.build_from_performance_dashboard(params)
    if params[:date_range]
      adjust_dates_for(params[:date_range])
    elsif params[:month]
      jump_to('month', params[:month], params[:reference_date])
    elsif params[:day]
      jump_to('day', params[:day], params[:reference_date])
    elsif params[:filter]
      new(params[:filter])
    else
      new(from: Date.today, to: Date.today)
    end
  end

  def convert_to_dates
    self.from = self.from.to_date
    self.to   = self.to.to_date
  end

  protected
  def self.adjust_dates_for(period)
    case period
      when "current_month"
        current_month
      when "last_month"
        last_month
      when "last_quarter"
        last_quarter
      when "current_year"
        current_year
      when "previous_year"
        previous_year
    end
  end

  def self.current_month
    new(from: Date.today.beginning_of_month, to: Date.today.end_of_month)
  end

  def self.last_month
    new(from: 1.month.ago.beginning_of_month.to_date, to: 1.month.ago.end_of_month.to_date)
  end

  def self.last_quarter
    last_quarter = Date.today.beginning_of_quarter - 1.day
    new(from: last_quarter.beginning_of_quarter, to: last_quarter.end_of_quarter)
  end

  def self.current_year
    new(from: Date.today.beginning_of_year, to: Date.today.end_of_year)
  end

  def self.previous_year
    new(from: 1.year.ago.beginning_of_year, to: 1.year.ago.end_of_year)
  end

  def self.jump_to(unit, direction, date)
    if direction == 'previous'
      desired_date = date.to_date - 1.send(unit)
    elsif direction == 'next'
      desired_date = date.to_date + 1.send(unit)
    end
    
    case unit
    when /month/
      new(from: desired_date.beginning_of_month, to: desired_date.end_of_month)
    when /day/
      new(from: desired_date, to: desired_date)
    end
  end

end
