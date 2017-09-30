class Quote < ApplicationRecord
  # Conflict with the quote method in activerecord?
  # http://api.rubyonrails.org/classes/ActiveRecord/ConnectionAdapters/Quoting.html#M000718
  belongs_to :delivery_state, :class_name => 'State', :foreign_key => 'delivery_state_id'
  belongs_to :source_state, :class_name => 'State', :foreign_key => 'source_state_id'
  belongs_to :customer
  has_many :containers
  has_many :trucker_quotes, :dependent => :destroy
  has_many :truckers, :through => :trucker_quotes
  validates_numericality_of :customer_amount
  validates_presence_of :delivery_city
  validates_presence_of :source_city
  validates_uniqueness_of :customer_id, :scope => [:delivery_city, :delivery_state_id, :source_city, :source_state_id, :triaxle]
  validates_presence_of :customer_id
  validates_presence_of :source_state_id
  validates_presence_of :delivery_state_id

  def to_s
    "Q#{id}"
  end

end
