class Accounting::Payment < Payment

  belongs_to :reconciliation, class_name: "Report::Reconciliation"
  belongs_to :payment_method, class_name: "PaymentMethod"
  has_many :line_item_payments, dependent: :destroy, class_name: "Accounting::LineItemPayment"

  accepts_nested_attributes_for :line_item_payments, allow_destroy: true, reject_if: proc { |attributes| attributes['line_item_id'].blank? }

  validates_each :cleared_date, allow_nil: true do |record, attribute, value|
     if record.cleared_date > Date.today
      record.errors.add :cleared_date, "cannot be from the future. Doc, you better back up. We don't have enough road to get to '88"
     end
  end

  before_validation :set_line_item_payments, :set_payment_method
  before_save :delete_unselected_lips, :computed_amount
  before_destroy  do
    throw :abort unless can_destroy?
  end

  scope :reconciled, ->{ where.not(reconciliation_id: nil) }

  def third_party?
    true
  end

  def reconciled?
    reconciliation.present?
  end

  def overpaid?
    self.balance > 0
  end

  validate do
    errors.add(:base, ABSTRACT_CLASS_INST_ERROR%"Accounting::Invoice") unless self.class != Accounting::Payment
    errors.add(:base, "Must select at least one line item") unless computed_amount > 0
  end

  def self.payment_methods
    PaymentMethod.names_and_ids.select {|m| ['Check', 'Card', 'Wire', 'Echeck', 'ACH'].index(m[0]) }
  end

  def self.generate(company, invoices, params={})
    params = { company_id: company.id, amount: 0, balance: 0}.merge(params)
    selected_lis = {}
    if !params["line_item_payments_attributes"].nil?
      params["line_item_payments_attributes"].each do |lip|
        selected_lis[lip[1]["line_item_id"].to_i] = 1 if lip[1]["selected_for_payment"] == "1"
      end
    end
    params["line_item_payments_attributes"] = []
    payment = new(params)
    invoices.each do |inv|
      inv.line_items.where('line_items.balance > ?', 0).each do |li|
        lip = { amount: li.balance, payment_id: payment.id, line_item_id: li.id }
        lip.merge(selected_for_payment: "1") if selected_lis[li.id] == 1
        payment.line_item_payments.build(lip)
      end
    end
    payment
  end

  def load_line_item_payments(invoices)
    selected_lis = {}
    line_item_payments.each do |lip|
      selected_lis[lip.line_item_id] = 1
    end
    invoices.each do |inv|
      inv.line_items.where("line_items.balance > ?", 0).each do |li|
        if selected_lis[li.id].nil?
          lip = { amount: li.balance, payment: self, line_item: li}
          line_item_payments.build(lip)
        end
      end
    end
    self
  end

  def self.total_amount
    self.all.map(&:amount).map(&:to_f).sum
  end

  def build_line_item_payments(lip_attributes)
    lip_attributes.delete_if do |lip|
      !lip["selected_for_payment"] || !lip["selected_for_payment"].to_i == 0
    end
    lip_attributes
    self.line_item_payments.build(lip_attributes)
  end

  def set_line_item_payments
    line_item_payments.each do |lip|
      lip.amount = lip.line_item.amount
    end
  end

  def set_payment_method
    payment_method ||= PaymentMethod.find_by_id payment_method_id if payment_method_id
  end

  def delete_unselected_lips
    line_item_payments.select {|lip| !lip.selected_for_payment}.each do |lip|
      before =  line_item_payments.size
      line_item_payments.delete(lip)
      after =  line_item_payments.size
      raise "nothing changed" if before == after
    end
  end

  def date
    issue_date
  end

  def can_edit?
    errors.add(:base, "Payment #{self.number} cannot be edited because it's associated with a reconcilation.") if reconciled?
    errors[:base].empty?
  end

  def can_destroy?
    errors.add(:base, "Payment #{self.number} cannot be deleted because it's associated with a reconcilation.") if reconciled?
    errors.add(:base, "Payment #{self.number} cannot be deleted because it has been cleared") unless cleared_date.nil?
    errors[:base].empty?
  end

  def computed_amount
    self.amount = line_item_payments.select{|lip| lip.selected_for_payment }.sum(&:amount) - total_credits
  end

end
