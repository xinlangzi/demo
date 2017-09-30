class Port < ApplicationRecord
  include HubAssociation
  belongs_to_hub presence: true

  has_many :rail_roads ,:dependent => :destroy
  validates :name,presence: true
  validates :name, uniqueness: true

  scope :for_customer_quote, ->{ where(customer_quote: true).includes(:rail_roads) }
  scope :for_driver_quote, ->{ where(driver_quote: true).includes(:rail_roads) }

  def self.options
    all.collect{|p| [p.name, p.id]}
  end

  def rail_road_options
    self.rail_roads.map{|rr| [rr.name, rr.id]}
  end
end
