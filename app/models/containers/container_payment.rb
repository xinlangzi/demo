class ContainerPayment < Payment
  include PaymentAdjustmentAssociation
  has_many_adjustments

  belongs_to :payment_method
  belongs_to :reconciliation, class_name: "Report::Reconciliation"
  has_many :line_item_payments, foreign_key: :payment_id, dependent: :destroy
  has_many :line_items, through: :line_item_payments

  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :balance, numericality: { greater_than_or_equal_to: 0 }

  validates_associated :line_item_payments
  validates_each :cleared_date, :allow_nil => true do |record, attribute, value|
     if record.cleared_date > Date.today
        record.errors.add :cleared_date, "cannot be from the future. Doc, you better back up.
                                          We don't  have enough road to get to '88"
     end
  end

  validates_each :balance, :amount do |record, attribute, value|
    if record.compute(attribute) != value
      record.errors.add attribute, "cached of #{value} does not match the computed value of #{record.compute(attribute)}"
    end
  end

  validates_each :amount do |record, attr, value|
    if record.computed_balance_including_new < 0
      record.errors.add :amount, "is less than the invoice payments already associated with it."
    end
  end

  validate if: ->(payment){ payment.reconciliation.present? } do |payment|
    errors.add(:base,"Payment #{self.number} cannot be edited because it's associated with a reconcilation.")
  end

  before_save :compact_line_item_payments
  after_update :save_line_item_payments

  before_create do
    throw :abort unless line_item_payments.all?(&:valid?)
  end

  before_destroy  do
    throw :abort unless can_destroy?
  end


  def reconciled?
    !self.reconciliation.nil?
  end

  def overpaid?
    self.balance > 0
  end

  def computed_balance
    amount - line_item_payments.reject{|lip| lip.new_record?}.map(&:amount).sum
  end

  def computed_balance_including_new
    amount - total_adjustments - total_credits - compute_posted_amount
  end

  def amount=(value)
    value = value.blank? ? 0 : value
    write_attribute(:amount, value)
  end

  def compute(what)
    case what.to_sym
      when :balance then computed_balance_including_new
      when :amount then amount
    end
  end

  def update_balance
    if balance != computed_balance
      self.balance = computed_balance
    end
  end

  def update_balance_including_new
    if balance != computed_balance_including_new
      self.balance = computed_balance_including_new
    end
  end

  def update_balance!
    save! if update_balance
  end

  def posted_amount
    balance - amount
  end

  # Creates an  payment for these line item payments attributes
  # lip_attributes is an array of attributes objects
  def self.generate(for_company, invoices)
    payment = new(company: for_company)
    payment.amount, payment.balance = 0, 0
    LineItem.includes(:invoice, :container).where("balance > ? AND invoice_id IN (?)", 0, invoices.map(&:id)).each do |li|
      lip = payment.line_item_payments.build(amount: li.balance)
      lip.line_item = li
      lip.payment = payment # for validation
    end
    payment
  end

  def new_line_item_payments=(lip_attributes)
    return unless lip_attributes
    lip_attributes.values.each do |attributes|
      lip = self.line_item_payments.build(attributes)
      lip.payment = self
    end
    update_amount if kind_of?(PayablePayment)
    update_balance_including_new
  end

  def existing_line_item_payments=(lip_attributes)
    return unless lip_attributes
    line_item_payments.reject(&:new_record?).each do |lip|
      lip.attributes = lip_attributes[lip.id.to_s]
    end
    update_amount if kind_of?(PayablePayment)
    update_balance_including_new
   end

  def compact_line_item_payments
    line_item_payments.select {|lip| !lip.selected_for_payment}.each do |lip|
      line_item_payments.delete(lip)
    end

    line_item_payments.select{|lip| lip.new_record?}.each do |lip|
      exist_lip = line_item_payments.detect{|exist_lip| !exist_lip.new_record?&&(exist_lip.line_item_id == lip.line_item_id)}
      if exist_lip
        exist_lip.amount+=lip.amount
        line_item_payments.delete(lip)
      end
    end
  end


   def save_line_item_payments
     line_item_payments.each do |lip|
       lip.save(validate: false) if lip.changed? # this is validated again when I save the payment
     end
   end

  # Returns all invoices associates with this payment
  def invoices
    inv = Hash.new # Using a hash to eliminate duplicate invoices (the ones that have more than one line item paid with this)
    line_item_payments.each do |lip|
      inv[lip.line_item.invoice_id] = lip.line_item.invoice
    end
    inv.values
  end

  def self.compare(attribute)

  end

  def update_amount
    self.amount = compute_posted_amount + total_adjustments + total_credits
  end

  def compute_posted_amount
    line_item_payments.select{|lip| lip.selected_for_payment}.map(&:amount).compact.sum
  end

  def compute_remaining_balance
    line_item_payments.select{|lip| !lip.selected_for_payment}.map(&:amount).compact.sum
  end

  def needs_adjustments?
    false
  end

  def can_edit?
    errors.add(:base,"Payment #{self.number} cannot be edited because it's associated with a reconcilation.") if reconciled?
    errors[:base].empty?
  end

  def can_destroy?
    errors.add(:base, "Payment #{self.number} cannot be deleted because it's associated with a reconcilation.") if reconciled?
    errors.add(:base, "Payment #{self.number} cannot be deleted because it has been cleared") unless cleared_date.nil?
    errors[:base].empty?
  end
end
