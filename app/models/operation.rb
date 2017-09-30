class Operation < ApplicationRecord
  has_paper_trail only: [:appt, :instructions, :operated_at, :operation_type_id, :trucker_id, :yard_id]

  attr_accessor :uid

  include ApplicationHelper
  include OperationAppointment
  include AlterRequestAssociation

  has_many_alter_requests operated_at: [:trucker]
  belongs_to :container, touch: true
  belongs_to :operation_type
  belongs_to :company
  belongs_to :yard
  belongs_to :trucker
  belongs_to :recipient, class_name: 'Trucker', foreign_key: 'recipient_id'
  belongs_to :linked, class_name: 'Operation', foreign_key: 'linked_id'
  has_one    :linker, class_name: 'Operation', foreign_key: 'linked_id'
  has_many :payable_container_charges, dependent: :destroy
  has_many :images, as: :imagable, dependent: :destroy

  validates :company_id, presence: true
  validates :yard_id, presence: true, if: ->{ is_drop? }
  validates_associated :company, on: :create

  validates_each :appt, on: :update do |record, attr, value|
    if record.appt_changed? && record.is_drop?
      if value.nil?
        record.errors.add(:base, "Must first clear the date on #{record.after.operation_type.name}.") if record.after&&record.after.operated_at
      else
        if record.operated_at
          record.errors.add(:base, 'Must be greater than the current operation date.') if record.operated_time > record.appt_time
          record.errors.add(:base, 'Must be less than the next operation date.') if record.after&&(record.appt_time > record.after.operated_time)
        end
      end
    end
  end

  validates_each :linked_id, on: :update do |record, attr, value|
    if record.linked&&record.linked.operated_at.nil?
      record.errors.add(:base, 'The target operation date must be set.')
    end
  end

  before_destroy do
    throw :abort unless can_destroy?
  end

  scope :unoperated, ->{ where(operated_at: nil) }
  scope :operated, ->{ where.not(operated_at: nil) }
  scope :delivery_mark, ->{ joins(:operation_type).where("operation_types.delivered = ?", true) }
  scope :return_mark, ->{ joins(:operation_type).where("operation_types.returned = ?", true) }
  scope :appt_at, ->(date) { where("DATE(appt) = ?", date) }
  scope :miles, ->{ select("SUM(distance)") }
  scope :traceable_by_customer, ->{ joins(:operation_type).where(operation_types: { traceable_by_customer: true }) }
  scope :for_user, ->(user){
    case user.class.to_s
    when 'Trucker'
      where(trucker_id: user.id)
    when 'CustomersEmployee'
      all
    when 'SuperAdmin', 'Admin', 'Crawler'
      all
    else
      raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :by_trucker, ->(trucker){ where(trucker_id: trucker.id) }
  scope :late_by_trucker, ->{
    late.where(delay_by_trucker: true)
  }

  # filter out the operaiton without any doc
  scope :missing_doc, ->{
    ### Operation1: Dirver 1, Operation2: Driver 2, Operation3
    ### Driver1 -> Operation1 & Operation2, Driver2 -> Operation3
    select("operations.*, containers.lock AS locked, IF(operations.pos = 1, operations.trucker_id, o.trucker_id) AS owner_id").
    joins(:operation_type, :container).
    joins("LEFT OUTER JOIN operations o ON o.pos + 1 = operations.pos AND o.container_id = operations.container_id").
    joins("LEFT OUTER JOIN images ON images.imagable_id = operations.id AND images.imagable_type = 'Operation'").
    where("IFNULL(containers.waive_docs, false) = FALSE AND operation_types.required_docs = TRUE AND images.id IS NULL").
    where("containers.appt_date < ?", Date.today).
    having("owner_id IS NOT NULL").
    order("containers.appt_date ASC, containers.appt_start ASC, operations.pos ASC")
  }

  # filter out the operaiton if empty, pending doc or rejected
  scope :pending_doc, ->{
    select("operations.*, containers.lock AS locked, IF(operations.pos = 1, operations.trucker_id, o.trucker_id) AS owner_id").
    joins([:operation_type, :container]).
    joins("LEFT OUTER JOIN operations o ON o.pos + 1 = operations.pos AND o.container_id = operations.container_id").
    joins("LEFT OUTER JOIN images ON images.imagable_id = operations.id AND images.imagable_type = 'Operation'").
    where("IFNULL(containers.waive_docs, false) = FALSE AND operation_types.required_docs = TRUE").
    where("images.id IS NULL OR images.status IN (0, 2)").
    group("operations.id, o.trucker_id").
    having("owner_id IS NOT NULL").
    order("containers.appt_date ASC, containers.appt_start ASC, operations.pos ASC")
  }

  enum appt_status: { late: 0, ontime: 1 }

  DATETIME = /\d{4}-\d{2}-\d{2} \d{2}:\d{2}/
  PAPER_TRAIL_TRANSLATION ={
    "company_id" => Proc.new{|id| Company.find(id).name},
    "trucker_id" => Proc.new{|id| Trucker.find(id).name},
    "recipient_id" => Proc.new{|id| Trucker.find(id).name},
    "operation_type_id" => Proc.new{|id| OperationType.find(id).name}
  }

  LOCKED_BY_INVOICE_ERROR = "Must not change when belonging to a payable invoice."
  LOCKED_BY_CONNECTION = "Must not change when belonging to a linked container"
  UNLINK_DISABLE_ERROR = "Unlinkable for one of these reasons: linkee operation date exists, linker or linkee is locked."

  # be careful after update order
  before_update :cancel_assign,             if: :trucker_id_changed?
  before_update :cancel_notify_by_linked,   if: :linked_id_changed?
  after_update  :company_changed,           if: :company_id_changed?
  after_update  :reset_recipient,           if: :trucker_id_changed?
  after_update  :remove_link,               if: :trucker_id_changed?
  after_update  :operation_date_changed,    if: :operated_at_changed?
  after_update  :mark_appt_status,          if: :operated_at_changed?
  after_update  :mark_delivered
  after_update  :chain_trucker
  after_update  :rebuild_mileage_with_appt, if: :appt_changed?
  after_update  :reset_est_ops_date,        if: :appt_changed?
  after_update  :linked_change,             if: :linked_id_changed?
  after_save    :route_changed
  after_save    :reset_vacation,            if: :trucker_id_changed?
  after_create  :store_uid
  after_destroy :sort_siblings
  after_destroy :reset_delivered
  after_destroy :rebuild_scheduled_trips

  delegate :name,            to: :operation_type
  delegate :is_drop?,        to: :operation_type
  delegate :is_prepull?,     to: :operation_type
  delegate :is_streetturn?,  to: :operation_type
  delegate :actual_appt?,    to: :operation_type
  delegate :appt_confirmed?, to: :operation_type
  delegate :time_required?,  to: :operation_type
  delegate :required_docs?,  to: :operation_type
  delegate :lock?, to: :container
  delegate :hub_id, to: :container
  delegate :container_no, to: :container
  delegate :chassis_no, to: :container

  def self.containers_by_trucker(date)
    containers_truckers = select('container_id, trucker_id').where("actual_appt = ? AND trucker_id IS NOT NULL", date).group('trucker_id, container_id')
    containers_truckers.inject({}) do |map, cts|
      (map[cts.trucker_id]||=[]) << cts.container_id
      map
    end
  end

  # filter out the operaiton without any doc for driver
  def self.missing_doc_for(user)
    confirmed_ids = Container.for_user(user).select("containers.id")
    missing_doc.having("owner_id = ? AND container_id IN (?)", user.id, confirmed_ids)
  end

  # filter out the operaiton without any approved doc for driver
  def self.pending_doc_for(user)
    confirmed_ids = Container.for_user(user).select("containers.id")
    pending_doc.having("owner_id = ? AND container_id IN (?)", user.id, confirmed_ids)
  end

  def operated_time
    OperatedTime.new(!time_required?, operated_at)
  end

  def appt_time
    OperatedTime.new(!time_required?, appt)
  end

  def set_complete_mileage(miles)
    update_column(:complete_mileage, miles)
  end

  def set_pickup_appt(appt)
    update_column(:appt, appt)
  end

  def set_actual_appt(appt)
    if update_column(:actual_appt, appt)
      reset_vacation
      mark_appt_status
    end
  end

  def operate(datetime, user)
    return errors.add(:base, 'Oops! No permission to update.') unless operated_at_updatable_by?(user)
    return errors.add(:base, 'Please confirm container first!') unless container.confirmed
    return errors.add(:base, 'Please confirm appointment first!') if user.is_admin? && delivery_mark? && !container.appt_scheduled?
    return errors.add(:base, 'Need to assign trucker first!') if (before ? before : self).trucker_id.nil?
    return errors.add(:base, 'Need to notify trucker first!') unless (before ? before : self).notified?
    return errors.add(:base, 'Please specify time!') if time_required? && (datetime.strip !~ DATETIME)
    return errors.add(:base, LOCKED_BY_INVOICE_ERROR) unless is_allowable_change_of_operated_at?

    check_datetime(datetime) do |error|
      return errors.add(:base, error) if error
    end
    update_attribute(:operated_at, datetime) # Skip Validation: important
  end

  def check_datetime(dt)
    #ArgumentError: argument out of range self.operated_at = '11/18/2015 10:15'
    self.operated_at = dt
    current_operated_time = operated_time
    _prev = self.before
    _next = self.after
    if is_drop?
      yield "Must be less than appointment date." if current_operated_time > appt_time
    end
    if _prev
      yield "Please first set date for #{_prev.operation_type.name}." if _prev.operated_at.nil?
      yield "Must be greater than the date on #{_prev.operation_type.name}." if _prev.operated_time > current_operated_time
      yield "Please first set previous appointment date." if _prev.is_drop?&&_prev.appt.nil?
    end

    if _next&&_next.operated_at
      yield "Must be less than the date on #{_next.operation_type.name}." if current_operated_time > _next.operated_time
    end
  end

  def cancel_operate
    _next = self.after
    return errors.add(:base, "Must first clear the date on #{_next.operation_type.name}.") if _next&&_next.operated_at
    return errors.add(:base, LOCKED_BY_INVOICE_ERROR) unless is_allowable_change_of_operated_at?
    return errors.add(:base, "Cannot remove date since it has receivable invoice(s).") if delivery_mark?&&container.receivable_invoices.present?
    return errors.add(:base, "Cannot remove date since it's linked from another container.") if self.linker
    self.update_attribute(:operated_at, nil)
  end

  def assign(trucker)
    return errors.add(:assign, 'Has driver already!') if self.trucker_id
    container.operations_attributes = { "#{self.id}" => attributes.except('created_at','updated_at').merge(trucker_id: trucker.id) }
    unless container.valid?
      container.errors.full_messages.each{|error| errors.add(:assign, error) }
    else
      update_attribute(:trucker_id, trucker.id)
    end
  end

  def cancel_driver
    return errors.add(:assign, LOCKED_BY_INVOICE_ERROR) if invoiced?
    if container.live_load?&&!container.with_prepull?
      return errors.add(:assign, "For live load can't delete driver if any operation date exists.") if siblings.map(&:operated_at).compact.present?
    else
      return errors.add(:assign, 'Need to remove operation date first.') if driver_operated?
      return errors.add(:assign, "Must first unlink containers before deleting the trucker.") if linkee_right_sibling?
    end
    update_attribute(:trucker_id, nil)
  end

  def cancel_previous_notify
    if recipient_id
      operations = mail_segment_operations
      OperationMailer.notify_trucker_unassigned(operations, recipient_id).deliver_now
      operations.map(&:reset_recipient)
    end
  end

  def cancel_assign
    cancel_previous_notify
    mile_segment_operations.each do |operation|
      operation.reset_trucker
      operation.payable_container_charges.destroy_all
    end
  end

  def cancel_notify_by_linked
    cancel_previous_notify
    linked.cancel_previous_notify if linked
  end

  def reset_trucker
    update_column(:trucker_id, nil)
    touch
  end

  def company_changed
    if company_id_was
      target = final? ? before : self
      target.mile_segment_operations.each do |operation|
        operation.payable_container_charges.destroy_all
      end unless target.nil?
    end
  end

  def reset_recipient
    update_column(:recipient_id, nil)
    touch
  end

  def remove_link
    if trucker_id.nil?
      last = mile_segment_operations(false).last
      last.update_column(:linked_id, nil)
      last.touch
    end
  end

  def mile_segment_operations(cross_containers=true)
    dms = DriverMileSegment.new(container)
    dms.build_linkeds if cross_containers
    dms.at_segment(self).operations rescue []
  end

  def mail_segment_operations(cross_containers=true)
    oms = OperationMailSegment.new(container)
    oms.build_linkeds if cross_containers
    oms.at_segment(self).operations rescue []
  end

  def to_s
    self.operation_type.name + ' for ' + self.container.to_s
  end

  def uid
    return self.id unless self.new_record?
    @uid||= "u#{rand(10**5)}"
  end

  def is_allowable_change_of_operated_at?
    container.no_payable_invoice_for_trucker? || (container.is_a?(ImportContainer)&&after.nil?)
  end

  def view_operated_at
    (time_required? ? self.operated_at.ymdhmp : self.operated_at.ymd) rescue nil
  end

  def public_view_operated_at
    view_operated_at unless has_alter_request?(:operated_at)
  end

  def view_appt_at
    ( (time_required? ? self.appt.ymdhm : self.appt.ymd) rescue nil ) if is_drop?
  end

  def recipients
    case self.operation_type.recipients
    when /All/
      [self.container.customers_employee, self.trucker]
    when /Trucker/
      [self.trucker]
    when /Customer/
      [self.container.customers_employee]
    else
      []
    end
  end

  def action_sequences
    actions = []
    unless self.final?
      actions << "Pull" if self.is_drop?&&self.linker.nil?
      actions << (actions.empty? ? "From" : "To")
      actions << "To"
      actions << "Drop" if self.after.is_drop?&&self.linked.nil?
    end
    actions.compact
  end

  def location_sequences
    locations = []
    unless self.final?
      locations << self.yard if self.is_drop?&&self.linker.nil?
      locations << self.company << self.after.company
      locations << self.after.yard if self.after.is_drop?&&self.linked.nil?
    end
    locations.compact
  end

  def mileage_sequences
    mileages = []
    unless self.final?
      mileages << self.yard_distance.miles if self.is_drop?&&self.linker.nil?
      mileages << self.distance.miles
      mileages << self.after.yard_distance.miles if self.after.is_drop?&&self.linked.nil?
    end
    mileages.compact
  end

  def rail_fee
    location_sequences.map(&:rail_fee).compact.sum
  end

  def tolls_fee
    location_sequences.map(&:address_state).compact.map(&:tolls_fee).compact.sum
  end

  def finalize
    update_columns(trucker_id: nil, distance: nil, yard_distance: nil)
  end

  def delivery_mark?
    self.operation_type.delivered?
  end

  def first?
    !self.new_record?&&(id == container.operation_ids.first)
  end

  def final?
    !self.new_record?&&(id == container.operation_ids.last)
  end

  def by_trucker?(user)
    user.is_trucker?&&((final? ? before : self).try(:trucker_id) == user.id)
  end

  def operatable_by?(user)
    user.is_trucker?&&((before || self).try(:trucker_id) == user.id)
  end

  def preset?
    !final?&&payable_container_charges.detect(&:preset?).present?
  end

  def do_prepull?
    after&&after.is_prepull?
  end

  def preset_fee
    payable_container_charges.detect(&:preset?).amount rescue nil
  end

  def payable_charge_fee
    payable_container_charges.map(&:amount).compact.sum
  end

  def drop_trip?
    self.is_drop? || self.after&&self.after.is_drop?
  end

  def prepull_trip?
    self.after.is_prepull? rescue false
  end

  def require_prepull_charge?
    payable_container_charges.where(chargable_id: PayableCharge.prepull.id).where(chargable_type: 'PayableCharge').empty?
  end

  def drop_miles
    return nil unless drop_trip?
    meters = (self.distance || 0.0)
    meters+= (self.yard_distance || 0.0) if linker.nil?
    meters+= ((self.after.yard_distance || 0.0) rescue 0.0) if linked.nil?
    (meters/METER_TO_MILE).round(2)
  end

  def leg_miles
    self.drop_miles || self.distance.miles.to_f
  end

  def linked?
    !unlinked?
  end

  def unlinked?
    self.linked.nil?&&self.linker.nil?
  end

  def linkable?
    self.after.is_drop? rescue false
  end

  def linkable_to?(operation)
    operation.is_drop?&&linkable?&&operation.linker.nil?
  end

  def link_to(operation)
    unlink do
      if update_attributes({ linked_id: operation.id })
        cur_connection = linked.container
        mile_segment_operations.each{|operation| operation.payable_container_charges.destroy_all}
        cur_connection.reload.check_connection
        container.reload.check_connection
      end
    end
  end

  def unlink
    Operation.transaction do
      if linked_id
        ori_connection = linked.container
        trucker_id_was = trucker_id
        unless link_editable?
          errors.add(:base, UNLINK_DISABLE_ERROR)
          raise ActiveRecord::Rollback
        end
        update_attribute(:trucker_id, nil)
        update_attribute(:linked_id, nil)
        update_attribute(:trucker_id, trucker_id_was)
        ori_connection.reload.check_connection
        container.reload.check_connection
      end
      yield if block_given?
    end
  end

  def link_editable?
    !(linked.driver_operated? || lock? || linked.lock?)
  end

  def linkee_right_sibling?
    return false if new_record? || final?
    dms = DriverMileSegment.new(self.container)
    segment = dms.at_segment(self)
    !segment.operations.first.linker.nil?
  end

  def notifiable?
    self.trucker_id&&(self.trucker_id!=self.recipient_id)
  end

  def mark_notify
    update_attribute(:recipient_id, self.trucker_id)
  end

  def notify(show_warnings=false)
    return errors.add(:notify, 'Invalid email address') unless CheckEmail.filter(trucker, :email, show_warnings).present?
    OrderMailer.notify_operations(self).deliver_now
  end

  def notified?
    self.trucker_id.present?&&(self.trucker_id == self.recipient_id)
  end

  # use to associate the parent
  def audit_parent
    self.container
  end

  def removable?
    !persisted? || operated_at.nil?&&!container.connected?&&container.operations_editable?
  end

  def company_editable?
    !persisted? || operated_at.nil?&&((final? ? before : self).mile_segment_operations.map(&:invoiced?).none? rescue true)
  end

  def yard_editable?
    !persisted? || !invoiced?
  end

  def driver_editable?
    return true if !persisted?
    actions = []
    actions << after
    actions << self if before.nil? # first operation
    actions.compact.map(&:operated_at).compact.empty?&&!linkee_right_sibling?&&!invoiced?
  end

  def driver_cancelable?
    !lock?&&trucker_id
  end

  def driver_operated?
    !final?&&(before.nil? ? self : after).operated_at
  end

  def siblings
    self.container.operations
  end

  def befores
    siblings.where("pos < ?", self.pos)
  end

  def before
    siblings.where("pos < ?", self.pos).last
  end

  def afters
    siblings.where("pos > ?", self.pos)
  end

  def after
    siblings.where("pos > ?", self.pos).first
  end

  def time_required_on_appt?
    time_required?
  end

  def sms_info
    "From: #{self.company.name}, #{self.after.operation_type.name}: #{self.after.company.name}, #{self.after.company.address.strip}, #{container.container_no}, PU# #{container.pickup_no} #{container.appointment}".strip rescue nil
  end

  def invoiced?
    payable_container_charges.where("line_item_id IS NOT NULL").count > 0
  end

  def operated_at_confirmed?
    operated_at.present? && !has_alter_request?(:operated_at)
  end

  def operated_at_approved!
    raise 'Please confirm appointment first!' if delivery_mark? && !container.appt_scheduled?
    notify_date_changed
  end

  def operated_at_updatable_by?(user)
    user.is_admin? || !operated_at_confirmed?
  end

  private
    def can_destroy?
      if container.present?
        errors.add(:base, LOCKED_BY_CONNECTION) if container.connected?
        errors.add(:base, LOCKED_BY_INVOICE_ERROR) unless container.operations_editable?
      end
      errors[:base].empty?
    end

    def operation_email
      self.operated_at.nil? ? self.operation_type.email_template_for_remove_date : self.operation_type.email_template_for_set_date
    end

    def operation_date_changed
      if operated_at_was != operated_at
        notify_date_changed unless has_alter_request?(:operated_at)
      end
    end

    def notify_date_changed
      if self.container.customer.use_edi
        unless self.operated_at.nil?
          container.customer.edi_provider.enqueue(214, {
            container_id: container.id,
            event_type: :actual,
            operation_id: self.id
          })
        end
      else
        self.recipients.each do |recipient|
          operation_email.send_email(recipient, self.id)
        end if to_notify?
      end
    end

    def to_notify?
      self.operated_at.nil? ? self.operation_type.email_when_remove_date : self.operation_type.email_when_set_date
    end

    def mark_appt_status
      if before
        return before.update_column(:appt_status, nil) if operated_at.nil?
        if actual_appt?
          if !before.is_drop? && !before.actual_appt?
            status = operated_at > container.final_appt ? :late : :ontime rescue nil
            status = Operation.appt_statuses[status] rescue nil
            before.update_column(:appt_status, status)
            before.update_column(:delay_by_trucker, before.late?)
            diff_mins = (operated_at - container.final_appt).div(60) rescue 0
            diff_mins = nil if diff_mins <= 0
            before.update_column(:delay_mins, diff_mins)
          end
        end
      end
    end

    def sort_siblings
      self.container.sort_operations
    end

    def mark_delivered
      if operated_at_changed?&&delivery_mark?&&befores.none?(&:delivery_mark?) # inherit the first operation with mark delivery feature.
        self.container.delivered = self.operated_at.present?
        self.container.delivered_date = self.operated_at
        self.container.save(validate: false)
      end
    end

    def reset_delivered
      if delivery_mark?&&befores.none?(&:delivery_mark?)
        self.container.delivered = false
        self.container.delivered_date = nil
        self.container.save
      end
    end

    def chain_trucker
      if linked&&(linked_id_changed? || trucker_id_changed?)
        linked.mile_segment_operations.each do |operation|
          operation.update_column(:trucker_id, self.trucker_id)
          operation.touch
        end
      end
    end

    def linked_was
      Operation.find(linked_id_was) rescue nil
    end

    def linked_change
      linked_was.send(:rebuild_mileage_with_appt) if linked_was
      rebuild_mileage_with_appt
    end

    def rebuild_scheduled_trips
      container.build_scheduled_trips
    end

    def rebuild_mileage_with_appt
      container.mileage_with_appt
    end

    def reset_est_ops_date
      container.update(est_ops_date: appt) if appt
    end

    def route_changed
      Container.routes_changed ||= (company_id_changed? || pos_changed? || yard_id_changed?)
    end

    def reset_vacation
      trucker.vacations.where(vstart: actual_appt).destroy_all if trucker
    end

    def store_uid
      Rails.cache.write(@uid, self.id, expires_in: 120.seconds) unless @uid.blank?
    end
end
