class DayLog < ApplicationRecord
  mount_uploader :file, ImageUploader

  validates :file, :issue_date, presence: true

  belongs_to :trucker
  belongs_to :user
  has_many :notifications, as: :notifiable

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin', 'Admin'
      all
    when 'Trucker'
      where(trucker_id: user.id)
    else raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :range, ->(from, to){
    where("issue_date >= ? AND issue_date<= ?", from, to)
  }

  scope :passed, ->{
    where(status: [1, 3])
  }

  enum status: { pending: 0, approved: 1, rejected: 2, hosv: 3 }

  before_create :init_status

  MOBILE_ICONS = {
    pending: 'orange ion-ios-circle-filled',
    approved: 'green ion-ios-checkmark',
    hosv: 'dark-green ion-android-alert',
    rejected: 'red ion-ios-close'
  }.freeze

  STATUS_NAMES = {
    pending: 'Pending',
    approved: 'Approved',
    rejected: 'Rejected',
    hosv: 'HOS Violation'
  }.freeze

  def status_name
    STATUS_NAMES[status.to_sym]
  end

  def file_exists?
    file.file.exists? rescue false
  end

  def image?
    file.try(:content_type) =~/image/
  end

  def approve!
    update!(status: :approved, comment: nil)
  end

  def reject!(comment)
    update!(status: :rejected, comment: comment)
  end

  def hosv!
    update!(status: :hosv, comment: nil)
  end

  def owner?(user)
    user_id == user.try(:id)
  end

  def can_write?(user)
    case user.class.to_s
    when 'Admin', 'SuperAdmin'
      true
    else
      owner?(user)&&pending?
    end
  end

  def self.delete_by!(id, user)
    daily_log = DayLog.for_user(user).find_by(id: id)
    raise "You can't access to this daily log." unless daily_log
    if daily_log.can_write?(user)
      raise "Failed to delete this daily log." unless daily_log.destroy
    else
      raise "You can't delete this daily log."
    end
    daily_log
  end

  def to_h
    {
      id: self.id,
      title: self.status.titleize,
      start: (self.issue_date.ymd rescue nil),
      end:   (self.issue_date.ymd rescue nil),
      mobileIcon: MOBILE_ICONS[self.status.to_sym],
      backgroundColor: bg_color
    }
  end

  def bg_color
    case status.try(:to_sym)
    when :pending
      '#FFA500'
    when :approved
      '#27AE60'
    when :hosv
      '#1e8449'
    else
      '#FF0000'
    end
  end

  def self.good_week?(user, invoice_date)
    monday = invoice_date.monday
    friday = monday.since(4.days)
    passed_dates = user.day_logs.passed.where(issue_date: (monday..friday)).pluck(:issue_date).sort
    ((monday..friday).to_a - passed_dates).empty?
  end

  private
    def init_status
      self.status||= :pending
    end

end
