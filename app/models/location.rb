class Location < ApplicationRecord
  belongs_to :company

  validates :timestamp, uniqueness: { scope: [:company_id] }

  scope :for_hub, ->(hub){
    joins(:company).where("companies.hub_id = ?", hub.id)
  }

  scope :realtime, ->{
    where(
      id: where("timestamp >=?", Date.today.in_time_zone).group("company_id").select("MAX(locations.id)")
    ).order("timestamp ASC")
  }

  scope :timestamp_from, ->(data){
    where("timestamp >= ?", Time.zone.parse(data))
  }

  scope :timestamp_to, ->(data){
    where("timestamp <= ?", Time.zone.parse(data))
  }

  scope :waypoints, ->(data){
    unscoped.where(id: group("company_id").select("MAX(locations.id)")) if data=='last'
  }
  default_scope { order("timestamp ASC") }

  MAX_LOCATIONS = 60
  MIN_MOVING_METERS = 500

  def self.ransackable_scopes(auth=nil)
    [
      :timestamp_from,
      :timestamp_to,
      :waypoints
    ]
  end

  def self.users
    Company.joins(:locations).distinct
  end

  def self.store!(user, data)
    data = data.sort_by{|attr| attr[:utcTime].to_datetime }
    data.each do |attr|
      utc   = attr[:utcTime].to_datetime
      lat   = attr[:latitude].to_f
      lon   = attr[:longitude].to_f
      speed = attr[:speed]
      prev  = user.reload.locations.last
      move_meters  = Location.haversine(prev.latitude, prev.longitude, lat, lon) rescue MIN_MOVING_METERS
      if move_meters >= MIN_MOVING_METERS
        user.locations.create(timestamp: utc, latitude: lat, longitude: lon, speed: speed)
      else
        prev.update(timestamp: utc)
      end
    end
  end

  def to_h
    {
      latitude: latitude,
      longitude: longitude,
      timestamp: timestamp.us_datetime,
      trucker_id: company.id,
      trucker: company.name,
      time: timestamp.us_time
    }
  end

  def lat_lng
    [latitude, longitude].compact.join(",")
  end

  def address
    update_column(:address, query_address) unless self[:address]
    self[:address]
  end

  def map
    update_column(:map, base64_image_map) unless self[:map]
    self[:map]
  end

  def base64_image_map(width: 500, height: 300)
    url = GoogleMap.image_url(lat_lng, width: width, height: height)
    Base64.encode64(open(url).to_a.join)
  end

  def query_address
    GoogleMap.geocode(lat_lng).first.try(:address)
  end

  def self.remove_overdue
    Location.where("timestamp < ?", 7.days.ago).delete_all
  end

  def self.haversine(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    rm = 6371000 # Earth radius in meters
    lat1_rad, lat2_rad = lat1 * rad_per_deg, lat2 * rad_per_deg
    lon1_rad, lon2_rad = lon1 * rad_per_deg, lon2 * rad_per_deg
    a = Math.sin((lat2_rad - lat1_rad) / 2) ** 2 + Math.cos(lat1_rad) * Math.cos(lat2_rad) * Math.sin((lon2_rad - lon1_rad) / 2) ** 2
    c = 2 * Math::atan2(Math::sqrt(a), Math::sqrt(1 - a))
    rm * c # Delta in meters
  end
end
