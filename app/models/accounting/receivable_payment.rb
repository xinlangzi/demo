class Accounting::ReceivablePayment < Accounting::Payment

  has_many :line_items, through: :line_item_payments, class_name: "Accounting::ReceivableLineItem"

  validates :number, presence: true

end