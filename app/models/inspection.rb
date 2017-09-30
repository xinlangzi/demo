class Inspection < ApplicationRecord
  belongs_to :trucker
  has_many :images, as: :imagable, dependent: :destroy
  has_many :violations, dependent: :destroy
  has_many :adjustments, dependent: :destroy

  accepts_nested_attributes_for :violations,  allow_destroy: true
  accepts_nested_attributes_for :adjustments,  allow_destroy: true

  validates :issue_date, :amount, :point, :trucker_id, presence: true
  validates :amount, numericality: true

  validates_each :amount, on: :update do |record, attribute, value|
    if record.amount_changed?
      value||= 0.0
      adjusted_amount = record.adjustments.sum(:amount)
      if adjusted_amount < 0
        record.errors.add(attribute, "Must less than #{adjusted_amount}") if adjusted_amount.abs > value.abs
      else
        record.errors.add(attribute, "Must greater than #{adjusted_amount}") if adjusted_amount.abs > value.abs
      end
    end
  end

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin', 'Admin'
      all
    when 'Trucker'
      where(trucker_id: user.id)
    else raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :year, ->(year){
    where("issue_date >= ? AND issue_date < ?", Date.new(year.to_i), Date.new(year.to_i + 1))
  }

  scope :range, ->(from, to){
    where("issue_date >= ? AND issue_date <= ?", from, to)
  }

  scope :summary, ->{
    select("inspections.trucker_id, companies.name AS trucker_name, SUM(amount) AS total").
    joins(:trucker).
    group("inspections.trucker_id, companies.name").
    reorder("companies.name ASC")
  }

  default_scope { order('issue_date DESC') }

  before_destroy do
    throw :abort unless can_destroy?
  end

  LEVELS = %w{I II III IV}.freeze

  def self.ransackable_scopes(auth=nil)
    [:year]
  end

  def self.total(year, trucker)
    trucker.inspections.year(year).sum(:amount)
  end

  def name
    "#{trucker.name} on #{issue_date}"
  end

  def outstanding_invoices
    trucker.payable_invoices.outstanding
  end

  def computed_balance
    amount - adjustments.sum(:amount)
  end

  def clear?
    computed_balance == 0
  end

  def build_adjustment
    category = amount < 0 ? AdjustmentCategory.inspection_penalty : AdjustmentCategory.inspection_bonus
    adjustments.build(amount: computed_balance, category: category).tap do |adjustment|
      adjustment.save(validate: false)
    end
  end

  def self.to_csv(inspections)
    CSV.generate do |csv|
      csv << [
        "Issue Date",
        "Driver",
        "Level",
        "Point",
        "Amount",
        "Invoice No."
      ]

      inspections.each do |is|
        csv << [
          is.issue_date,
          is.trucker.name,
          is.level,
          is.point,
          number_to_currency(is.amount),
          is.adjustments.map(&:invoice).map(&:number).uniq.join(",")
        ]
      end
    end
  end

  def can_destroy?
    errors.add(:base, "You can't delete this inspection because it's associated with payment") if adjustments.any?(&:payment_id)
    errors[:base].empty?
  end

end
