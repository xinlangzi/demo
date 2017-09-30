class DriverQuote < CoreQuote

  attr_accessor :key

  def self.init
    new(key: rand(10**8))
  end

  def state
    State.find_by(abbrev: destination.split(',').map(&:strip)[-2])
  end

  def quick
    ret = {}
    sq = SpotQuote.new(
      hub: hub,
      miles: miles,
      container_size: ContainerSize.find_by(name: '40'),
      container_type: ContainerType.find_by(name: 'DV'),
      cargo_weight: 1,
      live_load: true,
      for_trucker: true
    )
    unless sq.set_base_rate_fee(false).nan?
      sq.driver_fuel_amount
      ret[:base_rate] = sq.base_rate_fee
      ret[:fuel_amount] = sq.fuel_amount
      ret[:fuel_percent] = sq.percent_fuel
      ret[:total] = sq.base_rate_fee + sq.fuel_amount
    end
    ret
  end

  def summary
    return @rates if @rates.present?
    @rates = {}
    if miles
      sq = SpotQuote.new(miles: miles) # round trip
      sq.for_trucker = true
      sq.hub = hub
      unless sq.set_base_rate_fee(false).nan?
        sq.tolls_fee = (state.try(:tolls_fee) || 0.0)*2
        sq.driver_fuel_amount
        sq.driver_toll_surcharge
        @rates[:base_rate] = sq.base_rate_fee
        @rates[:fuel_surcharge] = sq.fuel_amount
        @rates[:toll_surcharge_1] = sq.tolls_fee
        @rates[:toll_surcharge_2] = sq.toll_surcharge
      end
    end
    @rates
  end

  def total
    summary.values.sum
  end

  def to_h
    {
      key: key,
      rail_road_id: rail_road_id,
      destination: destination,
      miles: miles
    }
  end

end