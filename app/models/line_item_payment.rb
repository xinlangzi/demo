class LineItemPayment < ApplicationRecord

  attr_accessor :invoice_id, :container_id

  belongs_to :admin
  belongs_to :payment
  belongs_to :line_item

  validates :amount, numericality: { greater_than: 0 }
  validates :line_item_id, presence: true
  validates :payment_id, presence: true, unless: lambda{|lip| lip.payment.new_record?}
  validates_each :amount do |lip, attr, value|
    if lip.selected_for_payment
      lips = lip.payment.line_item_payments.select{|obj| obj.selected_for_payment}.group_by(&:line_item_id)[lip.line_item_id]
      unless lips.blank?
        changed_amount = lips.map(&:changed_amount).sum
        remaining_balance = lips.first.line_item.reload.balance
        if changed_amount > remaining_balance
          lip.errors.add :amount, "changed #{changed_amount} cannot be more than the remaining balance: #{remaining_balance}"
        end
      end
    end
  end

  before_validation :set_admin, on: :create
  after_save :update_line_item!
  after_destroy :update_line_item!

  def total_charged
    self.line_item.amount
  end

  def selected_for_payment=(value)
    @selected_for_payment = value.to_boolean
  end

  # returns the amount with what the amount has changed :)
  # positive it has risen
  def changed_amount
    if changes["amount"]
      (changes["amount"].last || BigDecimal("0")) - (changes["amount"].first || BigDecimal("0"))
    else
      BigDecimal('0')
    end
  end

  def selected_for_payment
    if new_record?
      @selected_for_payment
    else # when it's existing, it needs to be true by default, unless set to false
      if @selected_for_payment.nil?
        true # return the default state, which is true
      else
        @selected_for_payment #return the customized state
      end
    end
  end

  def selected=(attr)
    @selected = true if attr.to_s == '1'
  end

  private
    def set_admin
      self.admin||= User.authenticated_user
    end

    def update_line_item!
      # do not update line item if line item is deleted this might come up if it's a cascade delete started from the line_item.destroy
      line_item.update_balance! unless line_item.frozen?
    end
end
