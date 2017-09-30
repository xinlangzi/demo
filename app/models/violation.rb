class Violation < ApplicationRecord
  belongs_to :inspection

  validates :code, :unit, :description, presence: true
end
