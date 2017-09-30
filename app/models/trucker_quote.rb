class TruckerQuote < ApplicationRecord
  belongs_to :quote
  belongs_to :trucker
  validates_numericality_of :amount
  validates_presence_of :trucker_id
  
  def to_s
    "#{quote} for #{trucker}"
  end
end
