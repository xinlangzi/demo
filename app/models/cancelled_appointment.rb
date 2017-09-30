class CancelledAppointment < ApplicationRecord
  belongs_to :container
  belongs_to :trucker

  validates :container_id, :trucker_id, :issue_date, :reason, presence: true

  default_scope { order('issue_date DESC') }

  def self.to_csv(appointments)
    CSV.generate do |csv|
      csv << [
        "Date",
        "Driver",
        "Container",
        "Container No.",
        "Reason"
      ]

      appointments.each do |ca|
        csv << [
          ca.issue_date,
          ca.trucker.name,
          ca.container.id,
          ca.container.container_no,
          ca.reason
        ]
      end
    end
  end
end
