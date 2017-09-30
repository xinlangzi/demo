class AuditCharge < ApplicationRecord
  attr_accessor :user_id
  belongs_to :container
  belongs_to :assignee, class_name: 'Company', foreign_key: :assignee_id

  enum category: {
    undercharged_chassis_fee: 2,
    dispute_rail_chassis: 5,
    pending_task: 3,
    pending_receivable_charge: 0,
    pending_payable_charge: 1,
    profit_loss: 4
  }
  enum error: {
    dispatch_error: 0,
    driver_error: 1,
    other_error: 2
  }
  enum status: { await_to_resolve: 0, resolved: 1 }

  scope :with_errors, ->{
    where.not(error: nil)
  }

  before_create :default_status

  private

    def default_status
      self.status||= :await_to_resolve
    end

end
