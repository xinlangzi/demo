class CustomerQuote < CoreQuote

  def quick
    ret = {}
    sq = SpotQuote.new(
      hub: hub,
      miles: miles,
      container_size: ContainerSize.find_by(name: '40'),
      container_type: ContainerType.find_by(name: 'DV'),
      cargo_weight: 1,
      live_load: true
    ) # round trip
    unless sq.set_base_rate_fee(false).nan?
      sq.customer_fuel_amount
      ret[:miles] = miles
      ret[:base_rate] = sq.base_rate_fee
      ret[:fuel_amount] = sq.fuel_amount
      ret[:fuel_percent] = sq.percent_fuel
      ret[:total] = sq.base_rate_fee + sq.fuel_amount
      ret[:adjust_base_rate] = (ret[:total]/(1 + 0.15)).round(2)
      ret[:adjust_fuel_amount] = ret[:total] - ret[:adjust_base_rate]
      ret[:adjust_fuel_percent] = 15.0
    end
    ret
  end

end