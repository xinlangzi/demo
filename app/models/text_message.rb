class TextMessage < ApplicationRecord
  attr_accessor :trucker_id

  belongs_to :company
  belongs_to :admin
  belongs_to :container

  validates :message, presence: true
  validate :check_phone_number

  before_create :send_sms, :set_admin

  default_scope { order(id: :desc) }

  SANDBOX_TWILIO_TXT_FROM = '15005550006'
  # SANDBOX_TWILIO_TXT_TO = '15005555555'
  EMPTY_PHONE = "No mobile phone number in DB"

  def check_phone_number
    if phone_number.blank?
      self.status = EMPTY_PHONE
      errors.add(:phone_number, EMPTY_PHONE)
    end
  end

  def send_sms
    begin
      msg = MyTwilio.setup.api.account.messages.create(
        from: from,
          to: phone_number,
        body: message
      )
      self.status = msg.status.try(:titleize)
    rescue => ex
      Rails.logger.warn(ex.to_s + "\n" + ex.backtrace.join("\n"))
      self.status = ex.message
    end
  end

  # def phone_number=(number)
  #   if Rails.env.development?# I can only send to my number when in trial
  #     write_attribute(:phone_number, SANDBOX_TWILIO_TXT_TO)
  #   else
  #     write_attribute(:phone_number, number)
  #   end
  # end

  def from
    if Rails.env.development? || Rails.env.test?
      SANDBOX_TWILIO_TXT_FROM
    else
      SystemSetting.default.caller_id_phone
    end
  end

  def set_admin
    self.admin||= User.authenticated_user
  end

  def self.configured?
    MyTwilio.configured?
  end

end
