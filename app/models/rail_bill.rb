class RailBill < Tableless

  DEFAULT_SUBJECT = "Rail billing request for container %s under booking# %s"
  RAIL_BILL_SENT = "Raill bill email is sent successfully."

  attr_accessor :container_id, :subject, :email, :content, :user_id

  validates :email, :subject, presence: true
  validates :email, multiple_email: true
  validates :content, presence: true, if: Proc.new{|rb| rb.container.is_reefer?}

  def self.build(container)
    new({
             email: container.ssline.rail_billing_email,
           subject: DEFAULT_SUBJECT%[container.container_no, container.ssline_booking_no],
      container_id: container.id
    })
  end

  def container
    Container.find(container_id)
  end

  def user
    User.find(user_id)
  end

  def to_h
    {
             email: email,
           subject: subject,
           content: content,
           user_id: user_id,
      container_id: container_id
    }
  end

  def save
    begin
      OrderMailer.delay.rail_bill(to_h)
      return RAIL_BILL_SENT
    rescue => ex
      return ex.message
    end
  end
end