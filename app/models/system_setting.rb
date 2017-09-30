class SystemSetting < ApplicationRecord
  there_can_be_only_one
  belongs_to :state

  titleize :driver_hr_manager, :ds_admin_name

  CHECK_VALID_FIELDS = [:dispatch_email, :quote_bcc_to, :quote_email_from, :incomplete_address_email_to]

  with_options presence: true do |wo|
    wo.validates :account_sid
    wo.validates :auth_token
    wo.validates :caller_id_phone
    wo.validates :invoice_statement_subject
    wo.validates :invoice_statement_body
    wo.validates :invoice_statement_from
    wo.validates :dispatch_email
    wo.validates :quote_bcc_to
    wo.validates :quote_email_from
    wo.validates :incomplete_address_email_to
    wo.validates :state_id
  end

  with_options multiple_email: true do |wo|
    wo.validates :quote_bcc_to
    wo.validates :driver_quote_bcc_to
    wo.validates :default_bcc_email
    wo.validates :incomplete_address_email_to
    wo.validates :invoice_statement_from
    wo.validates :invoice_statement_bcc
    wo.validates :driver_hr_email
  end

  validates :inspection_reward, numericality: { greater_than_or_equal_to: 0 }

  before_save do
    self.fuel_zone.try(:strip!)
  end

  def self.default
    first || init
  end

  def self.init
    SystemSetting.new.tap do |obj|
      obj.save(validate: false)
    end
  end

  def self.setup?
    system_setting = default
    system_setting.valid?
    (system_setting.errors.messages.keys&CHECK_VALID_FIELDS).empty?
  end

  def self.tasks_for_hired_driver
    SystemSetting.default.tasks_for_hired_driver.split(/,/).map(&:strip).remove_empty rescue []
  end

  def self.tasks_for_terminated_driver
    SystemSetting.default.tasks_for_terminated_driver.split(/,/).map(&:strip).remove_empty rescue []
  end

end
