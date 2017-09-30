class DropRate < ApplicationRecord
  include HubAssociation
  belongs_to_hub presence: true

  validates :rate, presence: true
  validates :miles, :rate, numericality: { greater_than_or_equal_to: 0}

  def value_at(val)
    (self.as_percent ? val*(rate/100.0) : rate).round(2)
  end

end
