class DriverStatus

  FULL_LOAD_MILES = 200

  STATUSES = %w{no_load half_load full_load unavailable}.freeze
  STATUS_ICONS = {
    no_load: "icons-green",
    half_load: "icons-orange",
    full_load: "icons-red",
    unavailable: "icons-gray"
  }

  attr_accessor :date, :id, :name, :phone, :miles, :load_factor, :weight_factor, :status, :containers

  def initialize(date, options={})
    @date = date.to_date
    @id = options.id
    @name = options.name
    @phone = options.phone.gsub(/\s+/,'') rescue ''
    @miles = options.miles.to_f rescue 0
    @load_factor = (options.weight_factor || default_weight_factor).to_f
    @containers = options.containers.to_i rescue 0
    summary_weight_factor
  end

  def driver
    Trucker.find_by(id: @id)
  end

  def default_weight_factor
    weekend? ? 0.0 : 1.0
  end

  def weekend?
    [6, 0].include?(@date.wday)
  end

  def status_icon
    STATUS_ICONS[status]
  end

  def free?
    [:unavailable].exclude?(status)
  end

  private

  def summary_weight_factor
    remain_factor = if load_factor == 0.0
      -1.0
    elsif miles >= FULL_LOAD_MILES || containers >= 2
      0.0
    elsif miles > 0
      load_factor - 0.5
    else
      load_factor - 0.0
    end
    @weight_factor, @status = case remain_factor
    when -1.0
      [-1.0, :unavailable]
    when 0.0
      [1.0, :full_load]
    when 0.5
      [0.5, :half_load]
    else
      [0.0, :no_load]
    end
  end
end
