class Fuel < ApplicationRecord
  include HubAssociation
  belongs_to_hub presence: true

  validates :price, numericality: { greater_than: 0 }

  default_scope { order('created_at DESC') }

  FUEL_URL = 'https://www.eia.gov/dnav/pet/pet_pri_gnd_a_epd2d_pte_dpgal_w.htm'
  FUEL_ZONES = [
    'East Coast (PADD1)',
    'New England (PADD 1A)',
    'Central Atlantic (PADD 1B)',
    'Lower Atlantic (PADD 1C)',
    'Midwest (PADD 2)',
    'Gulf Coast (PADD 3)',
    'Rocky Mountain (PADD 4)',
    'West Coast (PADD 5)',
    'West Coast less California',
    'California'
  ].freeze

  def self.latest_price(hub)
    latest(hub).try(:price).to_f
  end

  def self.latest(hub)
    hub.fuels.try(:first)
  end

  def self.save_price(hub, price)
    price = price.to_f.round(2)
    return if price <= 0
    latest = latest(hub)
    if latest.try(:price).to_f == price
      latest.touch
    else
      hub.fuels.create(price: price)
    end
  end
end
