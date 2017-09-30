class Vacation < ApplicationRecord
  belongs_to :user
  after_create :adjust

  validates :vstart, uniqueness: { scope: :user_id }

  scope :for_hub, ->(hub){
    joins(:user).where("companies.hub_id = ?", hub.id)
  }

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin', 'Admin'
      all
    when 'Trucker'
      where(user_id: user.id)
    else
      none
    end
  }

  scope :range, ->(from, to){
    where("vstart >= ? AND vstart<= ?", from, to)
  }

  def to_h
    {
      id: self.id,
      title: self.title,
      start: (self.vstart.ymd rescue nil),
      end:   (self.vend.ymd rescue nil),
      backgroundColor: bg_color,
      persisted: persisted?
    }
  end

  def title
    case self.user
    when Trucker
      self.user.name
    else
      @title
    end
  end

  def adjust
    if vstart.saturday? or vstart.sunday?
      self.weight_factor||= 0.0 #use decimal
      self.weight_factor+= 0.5
      self.weight_factor > 1.0 ? destroy : save
    else
      self.weight_factor||= 1.0 #use decimal
      self.weight_factor-= 0.5
      self.weight_factor < 0.0 ? destroy : save
    end
  end

  def bg_color
    case weight_factor
    when 1.0
      '#00CC29'
    when 0.5
      '#DBCD00'
    else
      '#A30000'
    end
  end

  def self.toggle(user_id, date)
    user = User.find(user_id)
    vacation = user.vacations.where(vstart: date).first
    if vacation
      vacation.adjust
    else
      user.vacations.create(vstart: date)
    end
  end

end