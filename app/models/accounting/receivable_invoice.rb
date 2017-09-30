class Accounting::ReceivableInvoice < Accounting::Invoice

  include InvoiceBase::ReceivableInvoice

  validates :number, presence: true
	validates :line_items, presence: true, on: :create

  has_many :line_items, class_name: "Accounting::ReceivableLineItem", foreign_key: :invoice_id, dependent: :destroy
  has_many :ehtmls, as: :ehtmlable

  before_validation :dummy_number
  after_create :auto_number
  validates :sent_to_whom, multiple_email: true

  def dummy_number
    self.number = "dummy#{self.company_id}" if (self.number.nil? || self.number.empty?) && self.new_record?
  end

  def auto_number
    update_attribute(:number, "TP#{id}") if number == "dummy#{self.company_id}"
  end

	def type_info
		Accounting::Category::REVENUE
	end

  def due_date
    self.issue_date + 15.days
  end

  def icon
    "fa fa-money green"
  end

end
