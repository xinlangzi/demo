class Accounting::PayableInvoice < Accounting::Invoice
	
	has_many :line_items, class_name: "Accounting::PayableLineItem", foreign_key: :invoice_id, dependent: :destroy

	validates :number, presence: true
  validates :line_items, presence: true, on: :create

	def type_info
		Accounting::Category::COST
	end

  def icon
    "fa fa-money red"
  end

end
