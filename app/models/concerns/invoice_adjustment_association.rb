module InvoiceAdjustmentAssociation
  extend ActiveSupport::Concern

  def needs_adjustments?
    false
  end

  def sum_adjustments(exclude=nil)
    adjustments.where.not(id: exclude).sum(:amount)
  end

  def sum_remaining_adjustments
    adjustments.where(payment_id: nil).sum(:amount)
  end

  module ClassMethods
    def has_many_adjustments
      has_many :adjustments, foreign_key: :invoice_id, dependent: :destroy
    end
  end
end