class Analysis::BaseRate < ApplicationRecord
  MILE_STEP = 20
  MAX_MILES = Rails.env.test? ? 100: 1600

  class SimpleLinearRegression

    def initialize(xs, ys)
      @xs, @ys = xs, ys
      if @xs.length != @ys.length
        raise "Unbalanced data. xs need to be same length as ys"
      end
    end

    def mean(values)
      total = values.reduce(0) { |sum, x| x + sum }
      Float(total) / Float(values.length)
    end

    def slope
      @slope||= Proc.new{|xs, ys|
        x_mean = mean(xs)
        y_mean = mean(ys)
        numerator = (0...xs.length).reduce(0) do |sum, i|
          sum + ((xs[i] - x_mean) * (ys[i] - y_mean))
        end

        denominator = xs.reduce(0) do |sum, x|
          sum + ((x - x_mean) ** 2)
        end
        (numerator / denominator)
      }.call(@xs, @ys)
    end

    def intercept
      @intercept||= mean(@ys) - (slope * mean(@xs))
    end

    def predict(x)
      intercept + slope * x
    end

  end

  class MR < Struct.new(:miles, :rate)
    def self.linear_regression(mile_rates, step)
      miles = mile_rates.map(&:miles)
      groups = []
      mile_rates.each do |mr|
        groups[mr.miles/step]||= []
        groups[mr.miles/step] << mr
      end
      groups.map.each_with_index do |group, index|
        next if group.blank?
        miles = group.map(&:miles)
        rates = group.map(&:rate)
        if miles.length > 1
          xmiles = (index+1) * step
          linear = SimpleLinearRegression.new(miles, rates)
          yrate = linear.predict(xmiles)
        else
          if miles.first%step == 0
            xmiles = miles.first
            yrate = rates.first
          else
            xmiles = (index+1) * step
            yrate = xmiles*(Float(rates.first)/Float(miles.first))
          end
          # puts "#{index}: #{miles.first} #{rates.first} #{xmiles}: #{yrate}"
        end
        MR.new(xmiles, yrate.round(0))
      end
    end

    def to_s
      "#{miles}: #{rate}"
    end
  end

  def self.mile_step
    (Rails.cache.fetch(:base_rate_mile_step) || MILE_STEP).to_i
  end

  def self.refer_hub_ids
    (Rails.cache.fetch(:base_rate_hub_ids) || []).uniq
  end

  def self.chart_data(id)
    data = []
    begin
      hub = Hub.find(id)
      ppg = Fuel.latest_price(hub)

      hubs = [hub]
      hubs+= Hub.where(id: refer_hub_ids) if hub.demo?

      step = mile_step
      mile_steps = (0..MAX_MILES).step(step.to_i)

      drivers = {}
      sq = SpotQuote.new(hub: hub)
      sq.for_trucker = true
      xys = mile_steps.map do |miles|
        sq.miles = miles
        drivers[miles] = (sq.set_base_rate_fee(false) + sq.driver_fuel_amount).to_i
        { x: miles, y: drivers[miles] }
      end
      data << { key: 'Driver', values: xys }

      sq.for_trucker = false
      hubs.each do |hub|
        sq.hub = hub
        xys = mile_steps.map do |miles|
          sq.miles = miles
          rate = (sq.set_base_rate_fee(false) + sq.customer_fuel_amount(ppg)).to_i
          { x: miles, y: rate, profit: rate - drivers[miles] }
        end
        data << { key: hub.name , values: xys }
      end

      csv = CSV.parse(Rails.cache.fetch(:base_rate_csv){''})
      mile_rates = csv.map{|row| MR.new(row.first.to_i, row.last.to_i) }
      mile_rates = MR.linear_regression(mile_rates, step).compact
      xys = mile_steps.map do |miles|
        if mr = mile_rates.detect{|mr| mr.miles == miles }
          { x: miles, y: mr.rate, profit: mr.rate - drivers[miles] }
        end
      end.compact
      data << { key: 'Ref Rate', values: xys } if xys.present?
    rescue => ex
      logger.error(ex.message)
    end
    data
  end

  def self.sample(id)
    rows = []
    sq = SpotQuote.new
    sq.hub = Hub.find(id)
    miles = (5...100).step(5).to_a + (100..500).step(20).to_a + (550..1000).step(50).to_a + (1100..MAX_MILES).step(100).to_a
    miles = miles.select{|mile| mile <= MAX_MILES }
    miles.each do |mile|
      row = [0]*15
      row[0] = mile

      sq.miles = mile

      sq.for_trucker = true
      unless sq.set_base_rate_fee(false).nan?
        row[1] = sq.base_rate_fee
        sq.triaxle = false
        sq.driver_fuel_amount
        row[2] = sq.fuel_amount
        row[3] = sq.percent_fuel
        row[4] = sq.total

        sq.triaxle = true
        sq.driver_fuel_amount
        row[5] = sq.fuel_amount
        row[6] = sq.percent_fuel
        row[7] = sq.total
      end

      sq.for_trucker = false
      unless sq.set_base_rate_fee(false).nan?
        row[8] = sq.base_rate_fee
        sq.triaxle = false
        sq.customer_fuel_amount
        row[9] = sq.fuel_amount
        row[10] = sq.percent_fuel
        row[11] = sq.total

        sq.triaxle = true
        sq.customer_fuel_amount
        row[12] = sq.fuel_amount
        row[13] = sq.percent_fuel
        row[14] = sq.total
      end
      rows << row.collect{|n| n.round(2) }
    end
    rows
  end
end