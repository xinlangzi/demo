class Mobile::Status < ApplicationRecord
  self.table_name = "mobile_statuses"

  validates :device_id, presence: true

  default_scope { order("located_at DESC") }

  def self.record(uid, options={})
    return unless uid
    query(uid).tap do |status|
      status.update(options) if status.persisted?
    end
  end

  def self.query(uid)
    find_or_create_by(device_id: uid)
  end

  def user
    User.find_by(device_id: device_id)
  end

end
