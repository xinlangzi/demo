module InvoiceCreditAssociation
  extend ActiveSupport::Concern

  def sum_credits(exclude=nil)
    credits.where.not(id: exclude).sum(:amount)
  end

  def sum_remaining_credits
    credits.where(payment_id: nil).sum(:amount)
  end

  module ClassMethods
    def has_many_credits
      has_many :credits, foreign_key: :invoice_id, dependent: :destroy
    end
  end
end
