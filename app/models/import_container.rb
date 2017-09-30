class ImportContainer < Container

  validates :container_no, format: { with: CONTAINER_NO_FORMAT, message: "--- needs to be 4 letters followed by 6 numbers plus 1 optional check digit" }, allow_blank: true
  validates :rail_lfd, presence: { message: "is needed for confirmed orders" }, if: :confirmed?
  validates :pickup_no, presence: { message: "cannot be blank for confirmed orders" }, if: :confirmed?
  validates :terminal_eta, presence: true, if: :confirmed?

  PARTNER = 'consignee'
  FIELDS_TO_COPY = [:ssline_bl_no]
  check_status

  scope :undepoted, ->{
    joins({operations: :operation_type}).
    where( { operation_types: { returned: true }, operations: { operated_at: nil } }).
    where("containers.terminal_eta > '2014-01-01' OR containers.terminal_eta is null")
  }

  scope :pending_empty, ->{
    unlocked.
    select("containers.*, companies.name AS cname").
    joins({ operations: [:operation_type, { company: :address_state }] }).
    where({ operation_types: { returned: true }, operations: { operated_at: nil } }).
    where("1 = (SELECT COUNT(*) FROM operations WHERE container_id = containers.id AND operated_at IS NULL)")
  }

  def is_import?
    true
  end

  def warning
    infos = []
    infos << "Rail Last Free Day date" if (self.appt_date > self.rail_lfd + 5.days rescue false)
    infos << "Rail ETA date" if (self.appt_date > self.terminal_eta + 5.days rescue false)
    infos.empty? ? nil : "Appointment cannot be greater than 5 days of " + infos.to_sentence
  end

  def appt_too_late?
    (self.appt_date > self.rail_lfd rescue false)&&(operations.first.operated_at.nil? rescue true)
  end

  def self.build_similar_to(sample_container)
    ic = super(sample_container)
    ImportContainer::FIELDS_TO_COPY.each do |field|
      ic.send(field.to_s + "=", sample_container.send(field))
    end
    ic
  end

  def cargo_delivered?
    operations.detect(&:actual_appt?).try(:operated_at_confirmed?)
  end

  def progress_statuses
    statuses = []
    statuses << { name: :work_order_received, done: true }
    if !appt_scheduled?&&pick_up_date.present?
      statuses << { name: :container_picked_up_from_terminal, done: picked_up? }
      statuses << { name: :appt_scheduled, done: appt_scheduled? }
    else
      statuses << { name: :appt_scheduled, done: appt_scheduled? }
      statuses << { name: :container_picked_up_from_terminal, done: picked_up? }
    end
    statuses << { name: :cargo_delivered, done: cargo_delivered? }
    statuses
  end

  def pending_pickup_no?
    pickup_no.blank?
  end

  def pending_last_free_day?
    rail_lfd.blank?
  end

  def save_pickup_info!(attrs)
    self.attributes = attrs
    raise "Disallow to change pickup information since it's picked up!" if pick_up_date.present?
    if (changed.map(&:to_sym) & [:pickup_no, :rail_lfd]).present?
      partial_save(attrs)
      OrderMailer.delay.notify_pickup_info_confirmed(id, email_to)
    end
  end

end
