class PayablePayment < ContainerPayment
  include Payable
  attr_reader :edit_number # the checkbox that says I want to edit the number

  MINIMUM_CHECK_AMOUNT = 10
  MINIMUM_CHECK_ERROR = "Cannot create a payment where the total remaining balance minus the remaining adjustments for that invoice is less than $#{MINIMUM_CHECK_AMOUNT}."
  CHECK_PAYMENT_MAX_CONTAINERS = 20
  WARNING_FOR_CHECK_PAYMENT_MAX_CONTAINERS = "If the check payment method is chosen, you are limited to at most 20 containers per payment."

  validate do
    errors.add(:remaining_balance, MINIMUM_CHECK_ERROR) unless check_remaining_balance
  end

  validate :check_containers
  validates :edit_number, presence: { message: ": You edited the number but didn't select 'edit_number'" }, if: Proc.new{|payment| payment.number_changed? && payment.number.present? && (payment.payment_method == PaymentMethod.check) }
  validates :number, presence: true, unless: :is_check_payment?

  after_create do
    update_attribute(:number, "auto#{id}") if !number
  end

  alias_attribute :date, :issue_date

  def check_containers
    if self.payment_method&&self.payment_method.is_check?
      containers = line_item_payments.select{|lip| lip.selected_for_payment}.map(&:container_id).uniq.size
      errors.add(:base, WARNING_FOR_CHECK_PAYMENT_MAX_CONTAINERS) if containers > CHECK_PAYMENT_MAX_CONTAINERS
    end
  end

  def check_remaining_balance
    balances = line_item_payments.collect{|lip| lip.invoice_id = lip.line_item.invoice_id; lip}.group_by(&:invoice_id)
    balances.each{|key, value| balances[key] = value.group_by(&:line_item_id)}
    adjustments = adjustment_selectors.select{|ppd| !ppd.selected}.group_by(&:invoice_id)

    adjustments.each do |key, values|
      b = 0
      selected = false
      balances[key].each do |line_item_id, lips|
        selected = true if lips.detect{|lip| lip.selected_for_payment}
        amount_to_pay = lips.select{|lip| lip.selected_for_payment }.map(&:amount).sum
        b+= LineItem.find(line_item_id).send(self.new_record? ? :balance : :amount) - amount_to_pay
      end rescue 0
      next unless selected
      d = values.map(&:total).sum
      return false if b+d < MINIMUM_CHECK_AMOUNT
    end
    true
  end

  def self.quick_generate(for_company, invoices, attrs={}, to_save=true)
    invoices = Array(invoices).flatten
    payment = generate(for_company, invoices)
    payment.line_item_payments.map{|lip| lip.selected_for_payment = "1"}
    payment.attributes = attrs
    payment.number = nil if payment.payment_method&&payment.payment_method.is_check?
    payment.optional_adjustments(invoices, true)
    payment.optional_credits(invoices, true)
    payment.update_amount
    payment.save if to_save
    payment
  end

  def edit_number=(new_value)
    @edit_number = new_value.to_i == 1 ? true : nil
  end

  def printed?
    number
  end

  def needs_adjustments?
    company.instance_of?(Trucker)
  end
end
