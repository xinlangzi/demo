class EquipmentRelease < ApplicationRecord
  belongs_to :container
  belongs_to :user

  validates :email, :subject, presence: true
  validates :email, multiple_email: true

  DEFAULT_SUBJECT = "Equipment release request under booking# %s"
  EQUIPMENT_RELEASE_SENT = "Equipment release email is sent successfully."

  after_create :send_request

  def self.build(container)
    container.equipment_releases.build(
       email: container.ssline.eq_team_email,
     subject: DEFAULT_SUBJECT%[container.ssline_booking_no]
    )
  end

  private
  def send_request
    OrderMailer.delay.equipment_release(id)
  end
end
