class ExportContainer < Container

  attr_accessor :rail_bill, :equipment_release, :temperature

  validates :container_no, format: { with: CONTAINER_NO_FORMAT}, allow_blank: true
  validates :container_no, :ssline_booking_no, :seal_no, presence: true, if: :rail_bill
  validates :ssline_booking_no, :container_size_id, :container_type_id, presence: true, if: :equipment_release
  validates :rail_cutoff_date, presence: { message: "is needed for confirmed orders" }, if: :confirmed?
  validates :empty_release_no, presence: { message: "is needed for confirmed orders" }, if: :confirmed?
  validates :early_receiving_date, presence: true, if: :confirmed?

  validates_each :early_receiving_date do |record, attr, value|
    if record.early_receiving_date&&record.rail_cutoff_date.nil?
      record.errors.add :rail_cutoff_date, "can't be blank"
    end

    if (record.early_receiving_date >= record.rail_cutoff_date  rescue false)
      record.errors.add attr, "should be before rails cutoff date"
    end
  end

  validate do
    errors.add(:ssline_id, 'rail billing email is not valid') if rail_bill&&(ssline.nil? || !ssline.email_valid?(:rail_billing_email))
    errors.add(:ssline_id, 'EQ team email is not valid') if equipment_release&&(ssline.nil? || !ssline.email_valid?(:eq_team_email))
  end

  scope :pending_load, ->{
    unlocked.
    select("containers.*, companies.name AS cname").
    joins({ operations: [:operation_type, { company: :address_state }] }).
    where({ operation_types: { returned: true }, operations: { operated_at: nil } }).
    where("1 = (SELECT COUNT(*) FROM operations WHERE container_id = containers.id AND operated_at IS NULL)")
  }

  PARTNER = 'shipper'
  FIELDS_TO_COPY = [
    :house_booking_no,
    :ssline_booking_no,
    :vessel_name,
    :voyage_number,
    :early_receiving_date,
    :rail_cutoff_date
  ]

  check_status

  def is_export?
    true
  end

  def warning
    infos = []
    infos << "Rail Cutoff Date" if (self.appt_date > self.rail_cutoff_date + 5.days rescue false)
    infos << "Early Receiving Date" if (self.appt_date > self.early_receiving_date + 5.days rescue false)
    infos.empty? ? nil : "Appointment cannot be greater than 5 days of " + infos.to_sentence
  end

  def delivered_computed?
    operations.last.operated_at rescue false
  end

  # def late?
  #   return true if !delivered && rail_cutoff_date && (rail_cutoff_date < Date.today)
  # end

  def appt_too_late?
    ((self.appt_date > self.rail_cutoff_date rescue false) || (self.appt_date < self.early_receiving_date rescue false))&&(operations.last.operated_at.nil? rescue true)
  end

  def self.build_similar_to(sample_container)
    ec = super(sample_container)
    ExportContainer::FIELDS_TO_COPY.each do |field|
      ec.send(field.to_s + "=", sample_container.send(field))
    end
    ec
  end

  def to_rail_bill?
    !new_record?&&!lock?&&confirmed?&&!delivered_computed?
  end

  def to_equipment_release?
    !new_record?&&!lock?&&confirmed?
  end

  def container_no_updatable_by?(user)
    return true if user.is_admin?
    container_no.blank? || has_alter_request?(:container_no)
  end

  def cargo_loaded?
    operations.detect(&:actual_appt?).try(:operated_at_confirmed?)
  end

  def progress_statuses
    statuses = []
    statuses << { name: :work_order_received, done: true }
    if !appt_scheduled?&&pick_up_date.present?
      statuses << { name: :empty_container_picked_up, done: picked_up? }
      statuses << { name: :appt_scheduled, done: appt_scheduled? }
    else
      statuses << { name: :appt_scheduled, done: appt_scheduled? }
      statuses << { name: :empty_container_picked_up, done: picked_up? }
    end
    statuses << { name: :cargo_loaded, done: cargo_loaded? }
    statuses << { name: :terminal_container_ingate, done: returned? }

    statuses
  end
end
