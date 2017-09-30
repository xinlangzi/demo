class Accounting::LineItemPayment < LineItemPayment
  clear_validators!

  validates :amount, numericality: { greater_than: 0 }
  validates :line_item_id, presence: true

  validates_each :amount do |record, attr, value|
    unless record.line_item.balance > 0
      record.errors.add :amount, "cannot be more than the line item balance: #{record.line_item.balance}"
    end
  end

end