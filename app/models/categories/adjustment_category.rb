class AdjustmentCategory < Category
  has_many :adjustments, foreign_key: :category_id , dependent: :restrict_with_exception

  INSPECTION_PENALTY = 'Roadside Inspection Penalty'
  INSPECTION_BONUS = 'Roadside Inspection Bonus'

  def self.inspection_penalty
    where(name: INSPECTION_PENALTY, number: :negative).first_or_create
  end

  def self.inspection_bonus
    where(name: INSPECTION_BONUS, number: :positive).first_or_create
  end

end
