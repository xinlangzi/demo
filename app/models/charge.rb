class Charge < ApplicationRecord
  belongs_to :accounting_group, class_name: 'Accounting::Group', foreign_key: :accounting_group_id
  has_many :credits, as: :catalogable

  validates :name, presence: true
  validates :amount, :percentage, numericality: true, allow_nil: true

  validates_each :amount do |record, attribute, value|
    if record.amount && record.percentage
      record.errors.add :amount, "and Percentage cannot both be set at the same time."
      record.errors.add :percentage, "and Amount cannot both be set at the same time."
    end
  end

  scope :default, ->{ where(hub_id: nil) }
  scope :mandatory, ->{ where.not(mandatory_sign: nil) }

  default_scope { order('ISNULL(seq_num), seq_num ASC, name ASC') }

  before_destroy do
    throw :abort unless can_destroy?
  end

  BUILTINS = [Settings.base_rate_name, "Base Rate", "Fuel Surcharge", "Triaxle", "Lift", "Other"]

  def self.base_rate
    where(name: Settings.base_rate_name).first
  end

  def receivable?
    false
  end

  def payable?
    false
  end

  def builtin?
    BUILTINS.include?(name)
  end

  def can_destroy?
    deletable = container_charges.empty? && !builtin?
    errors.add(:container_charges, "You cant't delete because you used it in previous containers.") unless deletable
    deletable
  end

  def by_hub(hub)
    overrides.where(hub: hub).first || self
  end

end
