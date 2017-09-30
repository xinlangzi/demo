class Adjustment < ApplicationRecord
  has_paper_trail on: [:update, :destroy]

  belongs_to :inspection
  belongs_to :invoice, class_name: 'PayableInvoice'
  belongs_to :payment, class_name: 'PayablePayment'
  belongs_to :category, foreign_key: :category_id
  has_many :images, as: :imagable, dependent: :destroy

  validates :category_id, presence: { message: "^Category can't be blank" }
  validates :amount, numericality: { less_than: 0 }, if: Proc.new{|adjustment| adjustment.category.try(:negative?) }
  validates :amount, numericality: { greater_than: 0 }, if: Proc.new{|adjustment| adjustment.category.try(:positive?) }

  validates_each :amount do |record, attr, value|
    if record.payment
      record.errors.add(:base, "The amount must not be changed because it's applied to payment")
    elsif record.invoice.nil?
      record.errors.add(:base, "Associate with invoice first")
    elsif record.invoice.balance + record.compute_balance + BigDecimal(value.to_s) < 0
      record.errors.add(:base, "The ABS amount must not be greater than the balance #{record.invoice.balance + record.compute_balance}")
    elsif record.inspection
      adjusted_amount = record.compute_inspection_adjusted_amount
      diff = record.inspection.amount.abs - adjusted_amount.abs
      if record.inspection.amount > 0
        record.errors.add(:base, "The max amount is #{diff}") if value.abs > diff
      else
        record.errors.add(:base, "The min amount is #{-diff}") if value.abs > diff
      end
    end
  end

  before_destroy :can_destroy?

  alias_method :orig_images, :images

  PAPER_TRAIL_TRANSLATION ={
    "category_id"        => ->(id){ Category.find(id).name }
  }

  def images
    (orig_images.to_a + (inspection.try(:images)||[])).compact
  end

  def name
    invoice.try(:company).try(:name)
  end

  def deduct_at
    invoice.issue_date
  end

  def compute_inspection_adjusted_amount
    inspection.adjustments.where.not(id: id).sum(:amount)
  end

  def compute_balance
    invoice.sum_adjustments(id)
  end

  def can_destroy?
    errors.add(:base, "This credit cannot be deleted because it's associated with a payment.") if payment
    errors[:base].empty?
  end

  def self.clear_up
    # Create adjustment without validation on adjustments/new. Request to clear up
    Adjustment.where(category_id: nil).delete_all
    Adjustment.where(invoice_id: nil).delete_all
  end
end
