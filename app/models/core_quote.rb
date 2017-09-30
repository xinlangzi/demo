class CoreQuote < Tableless

  attr_accessor :hub_id, :rail_road_id, :destination, :miles

  validates :rail_road_id, :destination, presence: true

  def hub
    Hub.find(hub_id || rail_road.port.hub_id) rescue nil
  end

  def rail_road
    RailRoad.find_by(id: rail_road_id)
  end

  def meters
    @meters||= GoogleMap.distance(rail_road.lan_lon.join(','), destination) rescue nil
  end

  def miles
    @miles||= (meters/METER_TO_MILE*2).round(2) rescue nil
  end

end