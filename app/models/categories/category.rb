class Category < ApplicationRecord

  titleize :name

  validates :name, presence: true, uniqueness: { scope: [:type], case_sensitive: false }
  validates :number, presence: true

  enum number: { negative: -1, positive: 1 }

  default_scope { order("name ASC") }

  alias_attribute :to_s, :name
end
