class ContainerLineItem < LineItem
  # Used in the generate invoice form, I can check_box what containers/line items I want
  attr_accessor :selected_for_invoice
  has_many :container_charges, foreign_key: :line_item_id, dependent: :nullify
  has_many :charges, through: :container_charges
  belongs_to :category, class_name: 'Accounting::Category'
  # Check if we have an invoice_id only if the invoice associated is saved
  # I check for li.invoice so I would not get an exception if there's no invoice
  validates :invoice_id, presence: true, unless: Proc.new{|li| li.invoice && li.invoice.new_record? }
  validates :container_id, presence: true
  validates :amount, :balance, numericality: true

  validates_each :balance do |record, attr, value|
    if record.computed_balance != record.balance
      record.errors.add attr, "cached of #{value} does not match the computed value of #{record.compute(attr)}"
    end
  end

  validates_each :amount do |record, attr, value|
    if record.computed_balance < 0
      record.errors.add :amount, "is less than the payment already associated with it."
    end
  end

  # duplicate line item checked - we don't want to invoice a container twice
  validates_each :container_id do |record, attr, value|
    existed_line_items = record.class.joins(:invoice).
      where(
        "line_items.id <> ifnull(?, 0) AND line_items.container_id = ? AND invoices.company_id = ?",
        record.id,
        record.container_id,
        record.invoice.company_id
      ).collect{ |li| li unless li.to_destroy }.compact
    record.errors.add(attr, " has already been invoiced in: #{existed_line_items.map{|li|li.invoice.number}.join(', ')}.") unless existed_line_items.empty?
  end

  validate do
    errors.add(:base, "You can not have an object of the base class, Line Item") unless self.class != LineItem
  end

  before_validation :update_balance # before save I update the balance
  after_save :update_invoice! # now that it's saved, with the balance updated, I want to update the invoice
  after_create :update_container_charges # I don't need an after_destroy because I have nullify in the has_many clause
  before_validation :set_defaults_on_create, on: :create

  scope :non_tp, ->{ where('line_items.type not like ?', '%Accounting%') }
  scope :tp, ->{ where('line_items.type like ?', '%Accounting%') }

  def update_amount!
    save! if update_amount
  end

  def paid?
    balance != amount
  end

  def fully_paid?
    balance == 0.0
  end

  def set_defaults_on_create
    self.balance = amount
  end

  def update_amount
    if self.amount != computed_amount
      self.amount = computed_amount
    end
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
    amount - line_item_payments.inject(0){|sum, lip| sum + lip.amount}
  end

  def computed_amount
    container_charges.inject(0){|sum, cc| sum + cc.amount}
  end

  def compute(what)
    case what.to_sym
      when :balance then computed_balance
      when :amount then computed_amount
    end
  end

  # I don't need to update the invoice when I create the invoice and the line_items alltoghether
  def update_invoice!
    invoice.update_cached_columns!
  end

  # This links up container charges to invoices
  def update_container_charges
    accounts = self.class.to_s.gsub('LineItem', '').downcase
    raise 'update_container_charges should be run in child classes!' unless %w(payable receivable).include?(accounts)
    # All charges for a company in a container should be in the same line item (separate receivable and payable)
    ori_line_items = []
    container.charges(accounts, invoice.company_id).each do |cc|
      ori_line_items << cc.line_item
      cc.line_item_id = self.id
      cc.save!
    end
    ori_line_items.compact.uniq.each{|li| li.to_destroy }
  end

  def update_invoice
    # If a line_item has been changed, added or deleted, it should reflect in invoice.
    self.invoice.reload
    if self.invoice
      if self.invoice.line_items.count > 0
        self.invoice.update_cached_columns!
      else
      self.invoice.destroy if self.invoice.line_items.blank? # If there are no more line_items, then delete invoice
      end
    end
  end

  def can_destroy?
    self.container_charges.empty?
  end

  def to_destroy
    if self.can_destroy?
      destroy
      update_invoice
    end
  end

  require_dependency 'payable_line_item'
  require_dependency 'receivable_line_item'
end
