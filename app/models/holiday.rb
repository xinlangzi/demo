class Holiday < ApplicationRecord

  validates :title, :vstart, presence: true

  scope :range, ->(from, to){
    where("vstart >= ? AND vstart<= ?", from, to)
  }

  def to_h
    {
      id: self.id,
      title: self.title,
      start: (self.vstart.ymd rescue nil),
      end:   (self.vend.ymd rescue nil)
    }
  end

  def self.include?(date)
    where("vstart = ? OR (vstart <= ? AND vend >= ?)", date, date, date).exists?
  end

end
