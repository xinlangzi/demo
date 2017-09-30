class Accounting::LineItem < LineItem
	# self.table_name = "line_items"
	# self.store_full_sti_class = true
	belongs_to :category, class_name: 'Accounting::Category'
  # has_many :line_item_payments, class_name: "Accounting::LineItemPayment",  dependent: :destroy
  # has_many :payments, through: :line_item_payments

	validates :category_id, presence: true
  validates :amount, numericality: { greater_than: 0 }

  before_validation :set_defaults_on_create, on: :create
  before_validation :update_balance

  after_save :update_invoice!
  after_destroy :update_invoice!

  validate do
    errors.add(:base, ABSTRACT_CLASS_INST_ERROR%"Accounting::Invoice") unless self.class != Accounting::LineItem
  end

  def set_defaults_on_create
    self.balance = amount
  end

  def update_invoice!
    invoice.update_cached_columns!
  end

  def update_balance
    if balance != computed_balance
      self.balance = computed_balance
    end
  end

  def update_balance!
    save! if update_balance
  end

  def computed_balance
    amount - line_item_payments.map(&:amount).sum
  end

end