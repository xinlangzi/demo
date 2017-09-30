class Accounting::Invoice < Invoice

  include InvoiceSearch
  include InvoiceCreditAssociation
  has_many_credits

  has_many :line_items, foreign_key: :invoice_id, dependent: :destroy
  accepts_nested_attributes_for :line_items,  allow_destroy: true

  validates :issue_date, :company_id, presence: true
  validates :number, uniqueness: {scope: [:company_id], case_sensitive: false }

  before_validation :set_defaults_on_create, on: :create
  before_save :update_balance, :update_amount
  before_destroy do
    throw :abort unless can_destroy?
  end

  scope :filter, ->(f){ f.sql_conditions(self) }
  scope :total, ->{ select("ifnull(sum(invoices.amount), 0) AS total") }
  scope :total_by_company, ->{
    select("ifnull(sum(amount), 0) as amount, ifnull(sum(balance), 0) as balance, company_id").
    group("invoices.company_id")
  }

  scope :performance, ->{
    joins([:company]).
    select("invoices.id AS id, invoices.number AS number, invoices.amount AS amount, invoices.company_id AS company_id, invoices.issue_date AS issue_date, companies.name AS company_name")
  }

  validate do
    errors.add(:base, ABSTRACT_CLASS_INST_ERROR%"Accounting::Invoice") unless self.class != Accounting::Invoice
  end

  def third_party?
    true
  end

  def info
    "#{number}: #{company.name}(#{issue_date.us_date}) Balance: $#{balance}"
  end

  def url
    "/#{self.class.to_s.pluralize.underscore}/#{self.id}"
  end

  def self.outstanding_companies_id(accounts)
    "Accounting::#{accounts.to_s.singularize.capitalize}Invoice".constantize.outstanding.pluck("DISTINCT company_id")
  end

  def can_destroy?
    errors.add(:base, "Invoice #{self.number} cannot be deleted because it has been partially or fully paid") if self.balance < self.amount
    errors[:base].empty?
  end

  def paid?
    !(self.new_record? || self.balance == self.amount)
  end

  def self.total_amount
    self.all.map(&:amount).map(&:to_f).sum
  end

  def self.total_balance
    self.all.map(&:balance).map(&:to_f).sum
  end

  def set_defaults_on_create
    self.balance = amount
  end

  def computed_amount
    line_items.map(&:amount).map(&:to_f).sum
  end

  def computed_balance
    line_items.map(&:balance).map(&:to_f).sum
  end

  def invalid_line_item_amount
    line_items.map(&:amount).map(&:to_f).select{|b| b < 0}.count > 0
  end

  def update_balance
    if self.balance != computed_balance
      self.balance = computed_balance
    end
  end

  def update_amount
    if self.amount != computed_amount
      self.amount = computed_amount
    end
  end

  def update_cached_columns!
    balance_updated = update_balance
    amount_updated = update_amount
    if balance_updated || amount_updated
      save!
    end
  end

  def build_line_items(line_items)
    line_items = line_items.delete_if do |li|
      delete = li["_destroy"] && li["_destroy"].to_boolean
      delete || li["amount"].empty?
    end.each do |li|
      li.delete "_destroy"
    end
    self.line_items.build(line_items)
  end

  def to_destroy
    destroy if line_items.empty?
  end


  def sum_adjustments
    0
  end

  def sum_remaining_adjustments
    0
  end

end