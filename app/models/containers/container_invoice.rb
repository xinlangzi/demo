class ContainerInvoice < Invoice

  has_many :line_items, foreign_key: :invoice_id, dependent: :destroy
  has_many :containers, through: :line_items
  has_many :edi_exchanges, class_name: Edi::Exchange, foreign_key: :invoice_id, dependent: :nullify

  validates :line_items, presence: true, :on => :create
  validates :balance, numericality: { greater_than_or_equal_to: 0 }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates_each :balance, :amount do |record, attr, value|
    if BigDecimal.new(record.compute(attr).to_s) != BigDecimal.new(value.to_s)
      record.errors.add attr, "cached of #{value} does not match the computed value of #{record.compute(attr)}"
    end
  end

  validate do
    errors.add(:base, "You can not have an object of the base class, Invoice") unless self.class != Invoice
  end

  scope :filter, ->(f){ f.sql_conditions(self) }

  scope :unpaid, ->(company){
    joins(:line_items).where("line_items.balance > ? AND invoices.company_id = ?", 0, company.id)
  }

  scope :totals, ->{
    select("IFNULL(SUM(line_items.amount), 0) AS amount, IFNULL(SUM(line_items.balance), 0) AS balance, company_id, COUNT(DISTINCT invoices.id) AS containers_count").
    joins(:line_items).
    order("amount DESC").
    group("invoices.company_id")
  }

  # scope :balance_sheet, ->{
  #   sql1 = Charge.joins(:accounting_group).where("accounting_groups.balance_sheet = ?", true).select(:id)
  #   sql2 = Accounting::Category.joins(:accounting_group).where("accounting_groups.balance_sheet = ?", true).select(:id)
  #   joins(line_items: :container_charges).
  #   where("(chargable_type = 'Charge' AND chargable_id IN (#{sql1.to_sql})) OR (chargable_type = 'Accounting::Category' AND chargable_id IN (#{sql2.to_sql}))")
  # }

  # scope :profit_loss, ->{
  #   sql1 = Charge.joins(:accounting_group).where("accounting_groups.profit_loss = ?", true).select(:id)
  #   sql2 = Accounting::Category.joins(:accounting_group).where("accounting_groups.profit_loss = ?", true).select(:id)
  #   joins(line_items: :container_charges).
  #   where("(chargable_type = 'Charge' AND chargable_id IN (#{sql1.to_sql})) OR (chargable_type = 'Accounting::Category' AND chargable_id IN (#{sql2.to_sql}))")
  # }

  scope :had_been_exported_to_quickbooks, -> { where(exported_to_quickbooks: true) }
  scope :pending_export_to_quickbooks, -> { where(exported_to_quickbooks: false) }

  attr_accessor :filter, :deleted, :generate_multiple

  before_save :update_balance, :update_amount
  before_validation :set_defaults_on_create, :set_due_date, on: :create

  delegate :invoice_j1s, to: :company

  def to_s
    "#{id} NO.#{number}"
  end

  def info
    "#{number}: #{company.name}(#{issue_date.us_date}) Balance: $#{balance}"
  end

  def url
    "/#{self.class.to_s.pluralize.underscore}/#{self.id}"
  end

  def set_defaults_on_create
    self.balance = amount
  end

  # def payments
  #   @payments||= Payment.joins(:line_item_payments).where('line_item_payments.line_item_id IN (?)', line_items.map{|li|li.id}).group('payments.id')
  #   return @payments.blank? ? [] : @payments
  # end

  def computed_amount
    line_items.select{|l| !new_record? || (new_record? && l.selected_for_invoice)}.sum(&:amount)
  end

  def computed_balance
    line_items.select{|l| !new_record? || (new_record? && l.selected_for_invoice)}.sum(&:computed_balance)
  end

  def compute(what)
    case what.to_sym
      when :balance then computed_balance
      when :amount then computed_amount
    end
  end

  # Calculates the total amount for a group of invoices
  # This uses the already set scopes
  def self.total_amount
    self.all.map(&:amount).sum
  end

  # This uses the already set scopes
  def self.total_balance
    self.all.map(&:balance).sum
  end

  # returns the new balance if changed, nil if not changed
  def update_balance
    if self.balance != computed_balance
      self.balance = computed_balance
    end
  end

  # returns the new amount if changed, nil if not changed
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

  def update_invoice
    line_items.each do |li|
      li.update_line_item
    end
  end

  # I'm lazy, I don't want to create an accounts method in the child classes
  def self.accounts
    return :receivable if to_s =~ /Receivable/i
    return :payable if to_s =~ /Payable/i
    raise 'self.accounts: you should not use Invoice. Use child classes.'
  end

  # Creates an  invoice with the line items from a list of containers
  # All containers should belong to the customer
  def self.generate(for_company, for_containers)
    invoice = new(company_id: for_company.id)
    invoice.issue_date = Date.today
    for_containers.each do |c|
      li = invoice.line_items.build(container: c)
      li.amount = c.amount(accounts, for_company.id)
      li.invoice = invoice
    end
    invoice.amount = invoice.computed_amount
    invoice.balance = invoice.computed_balance
    invoice
  end

  def add_line_item(container)
    if container
      line_item = self.line_items.build(container_id: container.id)
      line_item.amount = container.amount(self.class.to_s.gsub('Invoice',''), company_id)
      line_item.selected_for_invoice = true
      line_item.invoice = self
    end
    self.amount = computed_amount
    self.balance = computed_balance
  end

  def delete_line_item(line_item)
    self.line_items.destroy(line_item)
    self.amount = computed_amount
    self.balance = computed_balance
  end

  def self.outstanding_companies_id(accounts)
    "#{accounts.to_s.singularize.capitalize}Invoice".constantize.outstanding.pluck("DISTINCT company_id")
  end

  def self.invoiced_companies_id(accounts)
    select("DISTINCT invoices.company_id").
    where("invoices.type = ?", "#{accounts.to_s.singularize.capitalize}Invoice").map(&:company_id)
  end

  def self.outstanding_totals
    outstanding.all(:include => :line_items,
      :select => 'ifnull(sum(invoices.amount), 0) as amount, company_id, count(*) as containers_count',
      :joins => :line_items,
      :group => 'invoices.company_id')
  end

  # if an invoice has been paid, it can't be deleted. To do so, one needs to delete the payments first, then the invoice itself.
  def can_destroy?
    if line_items
      line_items.each do |li|
        if li.payments && !li.payments.blank?
          errors.add(:base, "Invoice #{number} cannot be deleted because it has been partially or fully paid")
          return false
        end
      end
    end
    true
  end

  def self.the_very_first
    first
  end

  def set_due_date
    self.due_date = Date.today + Settings.invoice_due.days - 1.day
  end

end
