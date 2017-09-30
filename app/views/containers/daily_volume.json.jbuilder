json.containers @containers do |container|
  json.values do
    json.array!(container[1]) do |c|
      json.x c[0]
      json.y c[1]
    end
  end
  json.key container[0]
end
