json.mile_rates do
  json.array! @mile_rates, :hub_id, :regular, :triaxle, :key_fuel_price, :avg_mpg
end

json.customer_rates do
  json.array! @customer_rates, :hub_id, :miles, :rate, :fuel_ratio, :gallons
end

json.driver_rates do
  json.array! @driver_rates, :hub_id, :miles, :rate
end

json.drop_rates do
  json.array! @drop_rates, :hub_id, :miles, :rate, :as_percent, :type
end