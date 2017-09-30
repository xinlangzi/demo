class PaymentMethod < ApplicationRecord
  has_many :payments

  validates :name, presence: true

  def self.names_and_ids
    result = all.collect{|s| [s.name, s.id] }
    result << result.slice!(3)
  end

  def self.check
    find_by(name: 'Check')
  end

  def self.card
    find_by(name: 'Card')
  end

  def self.ach
    find_by(name: 'ACH')
  end

  def is_check?
    self.name.downcase == 'check'
  end

end
