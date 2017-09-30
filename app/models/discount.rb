class Discount < ApplicationRecord
  after_initialize :set_label
  belongs_to :company
  validates_numericality_of :amount

  def self.rate_for_all_customers
    Discount.find_by_company_id_and_label(nil, 'Customer') || Discount.create(:amount => 0, label: 'Customer')
  end

  def self.rate_for_all_truckers
    Discount.find_by_company_id_and_label(nil, 'Trucker') || Discount.create(:amount => 0, label: 'Trucker')
  end

  private

  def set_label
    self.label ||= self.company.class.to_s
  end

end
