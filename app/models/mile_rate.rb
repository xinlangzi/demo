class MileRate < ApplicationRecord
  include HubAssociation
  belongs_to_hub presence: true
  validates :regular, numericality: { greater_than: :triaxle }
  validates :triaxle, numericality: { greater_than: 0 }
  validates :regular, :triaxle, :key_fuel_price, :avg_mpg, presence: true

  def self.default(hub)
    where(hub_id: hub.id).first_or_create(regular: 6.5, triaxle: 4, key_fuel_price: 2.0, avg_mpg: 6.5)
  end

end
