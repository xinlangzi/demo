class HubInterchange < ApplicationRecord
  belongs_to :hub
  belongs_to :customer
  validates :edi, presence: true
  validates :customer_id, presence: true, uniqueness: { scope: [:hub_id] }
end
