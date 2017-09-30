class Maintenance < ApplicationRecord
  belongs_to :trucker
  has_many :images, as: :imagable, dependent: :destroy

  enum status: { pending: 0, approved: 1, rejected: 2 }

  validates :issue_date, presence: true
  validates :services, presence: true

  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin', 'Admin'
      all
    when 'Trucker'
      where(trucker_id: user.id)
    else raise "Authentication / Access error for #{user.class}"
    end
  }

  default_scope { order("issue_date DESC") }

  def name
    "#{trucker.name} on #{issue_date.us_date}"
  end

  def save_with_files(files)
    self.status = :pending
    files.map do |file|
      images.build(file: file, user: trucker, status: :approved)
    end
    save
  end

end
