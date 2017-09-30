class ContainerCalendarFilter

  attr_accessor :prev_week, :next_week, :from, :to

  def self.build(params={})
    options = {
      prev_week: params[:prev_week],
      next_week: params[:next_week],
      from: (params[:q][:appt_date_gteq] rescue nil),
      to: (params[:q][:appt_date_lteq] rescue nil)
    }
    new(options)
  end

  def initialize(options={})
    options.each{|k,v| instance_variable_set("@#{k.to_s}", v)}
  end

  def analyse
    today = Date.today
    if !(@from&&@to).nil?
      @from = @from.to_date
      @to = @to.to_date
      @prev_week = today.monday - 1.week
      @next_week = today.monday + 1.week
    elsif !(date = @prev_week|| @next_week).nil?
      @from = date = date.to_date
      @to = date + 6.days
      @prev_week = date - 1.week
      @next_week = date + 1.week
    else
      @from = today - 1
      @to = today + 3
      @prev_week = today.monday - 1.week
      @next_week = today.monday + 1.week
    end

  end

  def validate!
    raise "Invalid date range." if @from > @to
    raise "Please make date range be no more than 7 days." if @from + 6.days < @to
  end

  def to_search_params
    { appt_date_gteq: @from.to_s, appt_date_lteq: @to.to_s }
  end

end