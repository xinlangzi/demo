module PaymentAdjustmentAssociation
  extend ActiveSupport::Concern

  attr_accessor :adjustment_selectors

  class AdjustmentSelector < Tableless
    attr_accessor :selected, :total, :invoice_id, :adjustment_id

    after_initialize do
      self.selected = selected.to_boolean
      self.total = total.big_decimal
      self.invoice_id = invoice_id.to_i
      self.adjustment_id = adjustment_id.to_i
    end
  end

  def related_adjustments=(attrs)
    @adjustment_selectors = (attrs||{}).values.collect{|attr| AdjustmentSelector.new(attr)}
  end

  def adjustment_selectors
    @adjustment_selectors||= adjustments.map do |adjustment|
      AdjustmentSelector.new(selected: true, total: adjustment.amount, invoice_id: adjustment.invoice_id, adjustment_id: adjustment.id)
    end
  end

  def optional_adjustments(invoices, selected=false)
    adjustment_selectors.tap do |dss|
      Adjustment.where(invoice_id: invoices.map(&:id)).where(payment_id: nil).each do |adjustment|
        dss << AdjustmentSelector.new(selected: selected, total: adjustment.amount, invoice_id: adjustment.invoice_id, adjustment_id: adjustment.id)
      end
    end
  end

  def total_adjustments
    adjustment_selectors.select{|c| c.selected }.sum(&:total)
  end

  def total_adjustments_amount
    adjustments.sum(:amount)
  end

  def mark_adjustments
    adjustment_selectors.each do |d|
      Adjustment.find(d.adjustment_id).update_attribute(:payment_id, (d.selected ? id : nil))
    end
  end

  module ClassMethods
    def has_many_adjustments
      has_many :adjustments, foreign_key: :payment_id, dependent: :nullify
      after_save :mark_adjustments
    end
  end
end