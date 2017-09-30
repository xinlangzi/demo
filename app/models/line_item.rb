class LineItem < ApplicationRecord
  belongs_to :invoice
  belongs_to :container
  has_many :line_item_payments, dependent: :destroy
  has_many :payments, through: :line_item_payments
end
