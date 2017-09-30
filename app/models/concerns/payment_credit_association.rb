module PaymentCreditAssociation
  extend ActiveSupport::Concern

  attr_accessor :credit_selectors

  class CreditSelector < Tableless
    attr_accessor :selected, :amount, :invoice_id, :credit_id

    after_initialize do
      self.selected = selected.to_boolean
      self.amount = amount.big_decimal
    end
  end

  def credit_selectors
    @credit_selectors||= credits.map do |credit|
      CreditSelector.new(selected: "1", amount: credit.amount, invoice_id: credit.invoice_id, credit_id: credit.id)
    end
  end

  def optional_credits(invoices, selected=false)
    credit_selectors.tap do |css|
      Credit.where(invoice_id: invoices.map(&:id)).where(payment_id: nil).each do |credit|
        css << CreditSelector.new(selected: selected, amount: credit.amount, invoice_id: credit.invoice_id, credit_id: credit.id)
      end
    end
  end

  def related_credits=(attrs)
    @credit_selectors = (attrs||{}).values.collect{|attr| CreditSelector.new(attr) }
  end

  def total_credits
    credit_selectors.select{|c| c.selected }.sum(&:amount)
  end

  def total_credits_amount
    credits.sum(:amount)
  end

  def mark_credits
    credit_selectors.each do |c|
      Credit.find(c.credit_id).update_attribute(:payment_id, (c.selected ? id : nil))
    end
  end

  module ClassMethods
    def has_many_credits
      has_many :credits, foreign_key: :payment_id, dependent: :nullify

      after_save :mark_credits
    end
  end
end