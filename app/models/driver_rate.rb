class DriverRate < ApplicationRecord
  include BaseRate
  include HubAssociation
  belongs_to_hub presence: true

  validates :rate, presence: true
  validates :miles, :rate, numericality: { greater_than: 0}

  scope :editable, ->{ where("miles > 0") }

end
