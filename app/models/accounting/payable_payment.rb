class Accounting::PayablePayment < Accounting::Payment

  include Payable

  has_many :line_items, through: :line_item_payments, class_name: "Accounting::PayableLineItem"

  validates :number, presence: true, unless: :new_check_payment?
  validates :number, uniqueness: { scope: :payment_method_id, case_sensitive: false }, if: :is_check_payment?


  after_create :auto_number

  attr_reader :edit_number

  def auto_number
    update_attribute(:number, "auto#{id}") if !number
  end

  def edit_number=(new_value)
    @edit_number = new_value.to_i == 1 ? true : nil
  end

  private

    def new_check_payment?
      is_check_payment? && new_record?
    end
end