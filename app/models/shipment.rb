class Shipment  < Tableless

  attr_accessor :container_id, :recipients, :comment, :customer,
                :request_pickup_no, :request_last_free_day,
                :location_id, :file_ids

  validates :recipients, multiple_email: true
  validates :comment, presence: true

  PICKUP_INFO_COMMENT = "Good Day, please enter required pick up information via link below. Thank you.".freeze

  def self.init(container)
    Shipment.new.tap do |it|
      it.container_id = container.id
      it.customer = container.customer
      it.recipients = container.customers_employee.try(:email)
    end
  end

  def container
    Container.find_by(id: container_id)
  end

  def location
    Location.find_by(id: location_id)
  end

  def files
    Image.unscoped.where(id: file_ids)
  end

  def email!
    raise errors.full_messages.join("; ") unless valid?
    ShipmentMailer.delay_for(5.seconds).email(to_h)
  end

  def to_h
    {
      container_id: container_id,
      recipients: recipients,
      comment: comment,
      location_id: location_id,
      file_ids: file_ids,
      request_pickup_no: request_pickup_no.to_boolean,
      request_last_free_day: request_last_free_day.to_boolean
    }
  end

  def doc_key
    "sd#{container_id}".to_sym
  end

  def auto_comment
    comment = self.comment.to_s.gsub(/#{PICKUP_INFO_COMMENT}/, '').strip
    if request_pickup_no.to_boolean || request_last_free_day.to_boolean
      comment = [PICKUP_INFO_COMMENT, comment].compact.join("\n\n").strip
    end
    comment
  end

end
