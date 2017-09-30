class ContainerQuote

  attr_accessor :container, :quotes, :visitor

  def initialize(container, visitor)
    @container = container
    @quotes = []
    @visitor = visitor
    build_quotes
  end

  private

  def build_quotes
    dms = DriverMileSegment.new(@container)
    dms.build_linkeds
    hub = @container.hub
    triaxle = @container.triaxle
    dms.view_segments(@visitor).each do |segment|
      full_miles = segment.miles
      quote = SpotQuote.new
      quote.hub = hub
      quote.for_trucker = true
      quote.triaxle = triaxle
      quote.miles = full_miles
      quote.gallon_price = Fuel.latest_price(hub)
      if segment.preset?
        quote = quote.dup
        quote.preset = true
        operation = segment.operations.first
        quote.operation_id = operation.id
        quote.base_rate_fee = operation.preset_fee
        quote.fuel_amount = 0
        @quotes << quote
      elsif segment.do_prepull?
      else
        quote.operation_id = segment.operations.first.id
        base_rate = quote.set_base_rate_fee(false)
        fuel_amount = quote.driver_fuel_amount
        if segment.drop_pull?
          drop_rate = DriverDropRate.interpolate(hub, full_miles).first
          base_rate = drop_rate.value_at(base_rate)
          fuel_amount = drop_rate.value_at(fuel_amount)
          unless drop_rate.as_percent
            fuel_amount = 0
            base_rate = base_rate*quote.combined_increases
          end
        end
        operations = segment.operations&@container.operations
        operations.each do |operation|
          quote = quote.dup
          quote.operation_id = operation.id
          quote.tolls_fee = operation.tolls_fee
          quote.miles = operation.leg_miles
          ratio = quote.miles/full_miles
          ratio = 0.0 if ratio.nan?
          quote.base_rate_fee = (base_rate*ratio).round(2)
          quote.fuel_amount = (fuel_amount*ratio).round(2)
          quote.driver_toll_surcharge
          @quotes << quote
        end
      end
    end
  end

end