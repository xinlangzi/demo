json.mileages(["Mileages"]) do |k|
  json.values do
    json.array!(@mileages_stats) do |cs|
      json.x cs[0]
      json.y cs[1]
    end
  end
end
