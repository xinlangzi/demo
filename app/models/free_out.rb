class FreeOut < ApplicationRecord
  belongs_to :ssline
  belongs_to :container_size
  belongs_to :container_type

  validates :days, :container_size_id, :container_type_id, presence: true
  validates :days, numericality: {greater_than_or_equal_to: 0}

  def container_style
    "#{self.container_size.name} #{self.container_type.name}"
  end

  def self.expiration_date(date, num)
    date = date.to_date
    while num > 0
      date+= 1.day
      num-=1 if !Holiday.include?(date)&&!date.saturday?&&!date.sunday?
    end
    date
  end
end