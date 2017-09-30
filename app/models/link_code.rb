class LinkCode < ApplicationRecord
  belongs_to :rail_road
  validates :name, presence: true, uniqueness: true
  validates :rail_road_id, presence: true
  validates :additional_fee, numericality: true

  default_scope { order("name ASC") }

  def self.rail_road(name)
    LinkCode.find_by(name: name).try(:rail_road)
  end

  def self.lan_lon(name)
    rail_road(name).lan_lon.join(', ') rescue nil
  end

  def self.additional_fee(name)
    LinkCode.find_by(name: name).additional_fee rescue 0
  end

end
