class Accounting::Group < ApplicationRecord
  self.table_name = "accounting_groups"

  has_many :categories, foreign_key: :accounting_group_id, dependent: :nullify
  has_many :charges, foreign_key: :accounting_group_id, dependent: :nullify

  validates :name, presence: true, uniqueness: { case_sensitive: false }


end
