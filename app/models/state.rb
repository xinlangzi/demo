class State < ApplicationRecord

  validates :tolls_fee, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :abbrev, uniqueness: true

  scope :driving, ->{ where(driving: true) }

  alias_attribute :to_s, :name

  def self.get_states_and_ids
    all.collect {|s| [s.name, s.id] }
  end

  def self.get_state_abbrev_and_ids
    all.collect {|s| [s.abbrev, s.id] }
  end
end
