class Notification < ApplicationRecord
  belongs_to :user, class_name: 'Company', foreign_key: :user_id
  belongs_to :notifiable, polymorphic: true
  enum category: {
    pending_j1s: 0,
    alter_request: 1,
    new_expiration_doc: 2,
    new_driver_application: 3,
    confirmed_without_appt_date: 4,
    drops_awaiting_pick_up: 5,
    mileages_updated: 6,
    daily_log: 7
  }

  default_scope { order('updated_at DESC') }

  after_create  :broadcast_create
  after_update  :broadcast_update
  after_destroy :broadcast_destroy

  def title
    category.titleize
  end

  private
    def broadcast_create
      ActionCable.server.broadcast "notification", { action: 'create', id: id }
    end

    def broadcast_update
      ActionCable.server.broadcast "notification", { action: 'update', id: id }
    end

    def broadcast_destroy
      ActionCable.server.broadcast "notification", { action: 'destroy', id: id }
    end

end
