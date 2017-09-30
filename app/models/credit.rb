class Credit < ApplicationRecord
  has_paper_trail on: [:update, :destroy]

  belongs_to :invoice
  belongs_to :payment
  belongs_to :catalogable, polymorphic: true
  has_many :images, as: :imagable, dependent: :destroy

  attr_accessor :catalogable_type_with_id

  validates :invoice_id, :amount, presence: true
  validates :catalogable, presence: { message: "^Category can't be blank" }
  validates :amount, numericality: { less_than: 0 }

  validates_each :amount do |record, attribute, value|
    record.errors.add(:base, "The amount must not be changed because it's applied to payment") if record.payment
  end

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin'
      all
    when 'Admin'
      if user.has_role?(:accounting)
        all
      else
        joins(:invoice).where("invoices.company_id NOT IN (?)", Company.where(acct_only: true).select(:id))
      end
    else raise "Authentication / Access error for #{user.class}"
    end
  }

  before_destroy :can_destroy?

  PAPER_TRAIL_TRANSLATION ={
    "catalogable_id"        => ->(id){ Accounting::Category.find(id).name }
  }

  def name
    invoice.try(:company).try(:name)
  end

  def catalogable_type_with_id
    "#{catalogable_type}-#{catalogable_id}"
  end

  def catalogable_type_with_id=(val)
    self.catalogable_type, self.catalogable_id = val.split("-")
  end

  def can_destroy?
    errors.add(:base, "This credit cannot be deleted because it's associated with a payment.") if payment
    errors[:base].empty?
  end

  def self.clear_up
    # Create credit without validation on credits/new. Request to clear up
    Credit.where(catalogable_type: nil, catalogable_id: nil).delete_all
  end
end
