class Container < ApplicationRecord
  has_paper_trail ignore: [:id, :created_at, :updated_at, :pin, :uuid, :type]

  extend ApplicationHelper
  include ApplicationHelper
  include ValidateContainer
  include ValidateOperation
  include HubAssociation
  include ContainerExport
  include AlterRequestAssociation

  nospace :chassis_no, :container_no, :house_bl_no, :ssline_bl_no
  uppercase :container_no, :chassis_no

  belongs_to_hub presence: true
  has_many_alter_requests chassis_no: [:trucker],
                          container_no: [:trucker],
                          chassis_pickup_at: [:trucker],
                          chassis_return_at: [:trucker]

  humanize_decimal_accessor :weight

  PAPER_TRAIL_TRANSLATION ={
    "hub_id"                => ->(id){ Hub.find(id).to_s },
    "customer_id"           => ->(id){ Customer.find(id).to_s },
    "container_size_id"     => ->(id){ ContainerSize.find(id).to_s },
    "container_type_id"     => ->(id){ ContainerType.find(id).to_s },
    "ssline_id"             => ->(id){ Ssline.find(id).to_s },
    "customers_employee_id" => ->(id){ CustomersEmployee.find(id).to_s },
    "street_turn_id"        => ->(id){ Container.find(id).to_s },
    "street_turn_type"      => ->(int){ Container.street_turn_types.key(int).titleize },
    "task_ids"              => ->(ids){ ContainerTask.where(id: ids).map(&:to_s) }
  }
  INACTIVE_TRUCKER_INFO = "The order belongs to a non-active trucker."
  INACTIVE_SSLINE_INFO = "The order belongs to a non-active ssline."
  SUCCESS_BUILD_PAYABLE_CHARGES = "Accts. payable charges were successfully constructed from quote engine!"
  XML_ATTRIBUTES = %w(rail_cutoff_date rail_lfd triaxle container_size_id container_type_id type ssline_id appt_date)
  CONTAINER_NO_FORMAT = /\A[A-Z]{4}\d{6,7}\Z/i
  RECEIVING_COMMENT = "Receiving"
  AWAITING_CONFIRMATION_COMMENT = "Awaiting Confirmation"
  ORDER_TAG = "order"

  SIGNIFICANT_CONTAINER_FIELDS = {
    container_size_id: ->(old, current){ ["Size/Type", [old.size, current.size]] },
    container_type_id: ->(old, current){ ["Size/Type", [old.size, current.size]] },
    triaxle: ->(old, current){ ["Triaxle", [old.triaxle, current.triaxle]] },
    container_no: ->(old, current){ ["Container No.", [old.container_no, current.container_no]] },
    pickup_no: ->(old, current){ ["Pickup No.", [old.pickup_no, current.pickup_no]] },
    appt_date: ->(old, current){ ["Appointment", [old.appointment, current.appointment]] },
    appt_start: ->(old, current){ ["Appointment", [old.appointment, current.appointment]] },
    appt_end: ->(old, current){ ["Appointment", [old.appointment, current.appointment]] },
    weight: ->(old, current){ ["Weight", [old.weight, current.weight]] },
    ssline_id: ->(old, current){ ["Ssline", [old.ssline.try(:name), current.ssline.name]] },
    commodity: ->(old, current){ ["Commodity", [old.commodity, current.commodity]] },
    rail_lfd: ->(old, current){ ["Rail Last Free Day", [old.rail_lfd, current.rail_lfd]] },
    empty_release_no: ->(old, current){ ["Empty Release No.", [old.empty_release_no, current.empty_release_no]] },
    rail_cutoff_date: ->(old, current){ ["Rail Cutoff Date", [old.rail_cutoff_date, current.rail_cutoff_date]] }
  }

  DUP_PAYABLE_CHARGES_ERROR = "An operation cannot have multiple Base Rate charges, multiple Rate Inclusive of Fuel charges, multiple Drop Fee charges, nor a combination thereof."
  UNIQ_CHARGES_PER_CONTAINER = ["Base Rate", "Rate Incl. of Fuel Surcharge", "Drop Fee"]

  enum chassis_loss_by: {
    chassis_loss_by_trucker: "trucker",
    chassis_loss_by_dispatcher: "dispatcher",
    chassis_loss_by_overbooked: "overbooked"
  } # to avoid scope query conflict, so I use prefix chassis_loss_by
  enum street_turn_type: { chassis_with_container: 0, only_chassis: 1 }

  belongs_to :customer
  belongs_to :customers_employee
  belongs_to :ssline
  belongs_to :container_size
  belongs_to :container_type
  belongs_to :chassis_pickup_company, class_name: 'Company', foreign_key: :chassis_pickup_company_id
  belongs_to :chassis_return_company, class_name: 'Company', foreign_key: :chassis_return_company_id
  belongs_to :street_turn, class_name: 'Container', foreign_key: :street_turn_id
  has_one    :container_edi_detail
  has_many :pods, dependent: :destroy
  has_many :edi_exchanges, class_name: Edi::Exchange, dependent: :destroy
  has_many :edi_logs, through: :edi_exchanges
  has_many :operations, ->{ order("pos ASC") }, dependent: :destroy
  has_many :cancelled_appointments, dependent: :destroy
  has_many :equipment_releases, dependent: :destroy, foreign_key: :container_id
  has_many :operation_types, through: :operations, class_name: "OperationType"
  has_many :audit_charges, dependent: :destroy
  has_many :container_charges, dependent: :destroy
  has_many :receivable_container_charges, extend: ContainerChargesExtension, after_add: [Proc.new{|cont, charge| charge.container = cont }], dependent: :destroy, autosave: true
  has_many :payable_container_charges, extend: ContainerChargesExtension, after_add: [Proc.new{|cont, charge| charge.container = cont }], dependent: :destroy, autosave: true
  has_many :line_items, dependent: :nullify
  has_many :invoices, through: :line_items
  has_many :payable_line_items, class_name: 'PayableLineItem'
  has_many :receivable_line_items, class_name: 'ReceivableLineItem'
  has_many :task_comments, dependent: :destroy
  has_many :images, as: :imagable, dependent: :destroy

  accepts_nested_attributes_for :operations, allow_destroy: true

  # check_status :truckers_active, otherwise: INACTIVE_TRUCKER_INFO
  check_status :ssline, should: :active?, otherwise: INACTIVE_SSLINE_INFO

  validates :hub_id, :ssline_id, :customer_id, :container_size_id, :container_type_id, :commodity, :reference_no, :customers_employee_id, presence: true
  validates :weight, numericality: {greater_than_or_equal_to: 0}
  validates :container_no, length: { maximum: 20 }
  validates :chassis_no, length: { maximum: 11 }
  validates :pickup_no, length: { maximum: 15 }
  validates :chassis_pickup_company_id, presence: true, if: Proc.new{|c| c.chassis_pickup_with_container.is_a?(FalseClass) }
  validates :chassis_return_company_id, presence: true, if: Proc.new{|c| c.chassis_return_with_container.is_a?(FalseClass) }
  validates :email_to, multiple_email: true
  validates_date :est_ops_date, on_or_after: :appt_date, allow_nil: true, unless: :appt_date_changed?
  validates_associated :payable_container_charges
  validates_associated :receivable_container_charges

  validate do
    errors.add(:base, "Operation with mark delivery must be present") if self.operations.detect(&:delivery_mark?).nil?
    errors.add(:appt_end, "must be later than Appt start") if invalid_appt_times?
    errors.add(:base, "Container #{self.id} is locked") if !self.new_record?&&self.lock?
    check_duplicate_payable_container_charges
    check_mandatory_charges
  end

  attr_accessor :vid, :weight_is_metric, :pdf, :appt_is_range, :to_save, :email_to
  cattr_accessor :routes_changed

  after_initialize :init_operations
  after_initialize :set_appt_is_range
  before_save :nullify_chassis_info
  before_save :nullify_appt_end
  before_save :convert_weight
  before_save :assign_interchange_id, if: Proc.new{|container| container.customer.use_edi && container.interchange_receiver_id.blank? }

  ############# PLH: Please make send_214_scheduled as the FIRST after_update ###################
  before_create :init_uuid
  after_create :notify_dispatcher
  after_update :send_214_scheduled
  after_update :send_truckers_notification
  after_update :save_container_charges
  after_save   :set_est_ops_date,  if: :appt_date_changed?
  after_save   :mileage_with_appt, if: :appt_date_changed?

  after_save :finalize_operation
  after_save :count_operations
  after_save :sort_operations
  after_save :schedule_trips

  scope :query, ->(num){
    num.downcase!
    where("id = ? OR lower(container_no) LIKE ? OR lower(ssline_bl_no) LIKE ? OR lower(ssline_booking_no) LIKE ?", num, "%#{num}%", "%#{num}%", "%#{num}%").
    order("id DESC")
  }

  scope :tracking, ->(nos){
    nos = nos.select{|no| !no.blank?}
    cnos = nos.map{|i| i=~/\A([A-Za-z]{4}\d{6})/; $1}.compact.join('|')
    if cnos.blank?
      where("ssline_booking_no IN (?) OR ssline_bl_no IN (?)", nos, nos)
    else
      where("container_no REGEXP ? OR ssline_booking_no IN (?) OR ssline_bl_no IN (?)", cnos, nos, nos)
    end
  }

  scope :filter, ->(f){ f.sql_conditions(self) }
  scope :confirmed, ->{ where("confirmed = ?", true) } # pending_receivable is false if confirmed is true
  scope :unconfirmed, ->{ where("confirmed = ? AND pending_receivable = ?", false, false) }# MUST combine pending_receivable
  scope :pending_receivables, ->{ where(pending_receivable: true) }
  scope :no_pending_receivables, ->{ where(pending_receivable: false) }
  scope :import, ->{ where(type: 'ImportContainer') }
  scope :export, ->{ where(type: 'ExportContainer') }
  scope :locked, ->{ where(lock: true) }
  scope :unlocked, ->{ where.not(lock: true) }
  scope :live_load, ->{
    where("NOT EXISTS ( SELECT * FROM operations
                        INNER JOIN operation_types ON operation_types.id = operations.operation_type_id AND operation_types.otype = 'Drop'
                        WHERE operations.container_id = containers.id )")
  }

  scope :drop_pull, ->{
    where("EXISTS ( SELECT * FROM operations
                    INNER JOIN operation_types ON operation_types.id = operations.operation_type_id AND operation_types.otype = 'Drop'
                    WHERE operations.container_id = containers.id )")
  }

  scope :for_user, ->(user){
    case user.class.to_s
    when 'CustomersEmployee'
      joins("LEFT OUTER JOIN container_charges ON container_charges.container_id = containers.id").
      where('containers.customer_id = ? OR container_charges.company_id = ?', user.customer.id, user.customer.id).
      group("containers.id")
    when 'Trucker'
      joins([:operations]).
      where("operations.recipient_id = ?", user.id).
      group("containers.id")
    when 'SuperAdmin', 'Admin', 'Crawler'
      all
    else raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :for_email, ->(email){
    joins(customer: :employees).
    where(employees_companies: { email: email })
  }

  scope :view_assocs, ->{ includes([
    :chassis_pickup_company, :chassis_return_company,
    { operations: [:images, :trucker, :payable_container_charges, :linker, :linked, :operation_type, { company: :address_state }] },
    { receivable_container_charges: [:container, :chargable, :company, :line_item] },
    { payable_container_charges: [:container, :chargable, :company, :line_item, :operation] }
  ])}

  scope :prealert_assocs, ->{
    includes([:customer, { operations: { company: :address_state } }])
  }

  scope :order_stack_assocs, ->{
    includes([
      :customer,
      :chassis_pickup_company,
      :chassis_return_company,
      {
        receivable_line_items: [
          :invoice,
          {
            line_item_payments: :payment
          }
        ]
      },
      {
        payable_line_items: [
          :invoice,
          {
            line_item_payments: :payment
          }
        ]
      },
      {
        operations: [
          :container,
          :operation_type,
          {
            company:
            :address_state
          },
          :trucker,
          :images
        ]
      }
    ])
  }

  scope :calendar_assocs, ->{
    includes([
      :customer,
      :ssline,
      :container_size,
      :container_type,
      :chassis_pickup_company,
      :chassis_return_company,
      { container_charges: :line_item },
      {
        operations: [
          :container,
          :operation_type,
          {
            company: :address_state
          },
          :trucker,
          :images
        ]
      }
    ])
  }

  scope :summary_charges, ->{
    select("
      containers.*,
      SUM(IF(ccs.type = 'ReceivableContainerCharge', ccs.amount, 0)) AS receivable_amount,
      SUM(IF(ccs.type = 'ReceivableContainerCharge', 1, 0)) AS receivable_count,
      SUM(IF(ccs.type = 'PayableContainerCharge', ccs.amount, 0)) AS payable_amount,
      SUM(IF(ccs.type = 'PayableContainerCharge', 1, 0)) AS payable_count
    ").
    joins("LEFT OUTER JOIN container_charges ccs ON ccs.container_id = containers.id").
    group("containers.id")
  }

  scope :appt_at, ->(from, to){
    where("appt_date >= ? AND appt_date <= ?", from, to)
  }

  scope :estimated_at, ->(from, to){
    joins(:operations).
    where("operations.appt >= ? AND operations.appt <= ?", from.to_time.beginning_of_day, to.to_time.end_of_day).
    group("operations.id")
  }

  scope :drop_without_estimated, ->{
    joins({operations: :operation_type}).
    where("operation_types.otype = ? AND operations.operated_at IS NOT NULL AND operations.appt IS NULL", 'Drop').
    group("containers.id")
  }

  def self.for_calendar(user, from, to)
    relation = summary_charges.for_user(user)
    unions = [
      relation.appt_at(from, to).select("containers.appt_date AS as_appt, 'with_appointment' AS group_name").to_sql,
      relation.estimated_at(from, to).select("DATE(operations.appt) AS as_appt, 'estimated' AS group_name").to_sql,
      relation.drop_without_estimated.select("containers.appt_date AS as_appt, 'drop_without_estimated' AS group_name").to_sql,
      relation.without_appt_date.confirmed.select("containers.appt_date AS as_appt, 'without_appointment' AS group_name").to_sql
    ].join(" UNION ")
    no_pending_receivables.calendar_assocs.from("(#{unions}) containers").group_by(&:group_name)
  end

  scope :delivered, ->{ where("containers.delivered = ?", true) }
  scope :open, ->{ where("containers.delivered IS NOT TRUE") } # include NULL and false
  scope :no_appointment, ->{ where('appt_date IS NULL') }
  scope :with_terminal_eta, ->{ where('terminal_eta IS NOT NULL') }
  scope :without_terminal_eta, ->{ where('terminal_eta IS NULL') }

  # Returns the container with no charges. Good for alerts when the dispatch forgot to add charges
  scope :uncharged, ->(accounts){
    container_charge_type = "#{accounts.to_s.downcase.singularize}_container_charge".classify
    includes([ :customer, { operations: { company: :address_state } } ]).
    joins("LEFT OUTER JOIN container_charges ON container_charges.container_id = containers.id AND container_charges.type = '#{container_charge_type}'").
    where("container_charges.id IS ?", nil)
  }

  # Jordan FIXME: If combine the Order scope, the result is alwasy empty
  scope :payable_operations_complete_enough_to_invoice, -> {
    where(<<DOC)
EXISTS (
  SELECT operations.container_id
    FROM operations
   WHERE operations.container_id = containers.id
GROUP BY operations.container_id
  HAVING SUM(IF(operations.operated_at is NULL, 1, 0)) <= IF(containers.type='ImportContainer', 1, 0))
DOC
}

  scope :uninvoiced_cached, ->(accounts){
    case accounts.to_s.downcase.to_sym
    when :receivable
      joins("LEFT OUTER JOIN container_charges ON container_charges.container_id = containers.id AND container_charges.type = 'ReceivableContainerCharge'").
      confirmed.
      where("container_charges.line_item_id IS ? AND delivered = ?", nil, true)
    else
      payable_operations_complete_enough_to_invoice.
      joins("LEFT OUTER JOIN container_charges ON container_charges.container_id = containers.id AND container_charges.type = 'PayableContainerCharge'").
      confirmed.
      where("container_charges.line_item_id IS ?", nil)
    end
  }
  scope :default, ->{ where(needs_edi_review: false) }
  scope :by_edi,  ->{ where(needs_edi_review: true).includes([:container_type, :container_size]) }

  scope :operations_without_documents, ->{
    joins([{ operations: :operation_type }]).
    joins("LEFT OUTER JOIN images ON images.imagable_id = operations.id AND images.imagable_type = 'Operation'").
    where("operations.operated_at IS NOT NULL AND images.id IS NULL AND operation_types.required_docs = true").
    order("containers.id DESC").
    group("containers.id")
  }

  scope :operations_without_mark_delivery, ->{
    ids = OperationType.where(delivered: true).pluck(:id)
    joins(:operations).
    group("containers.id").
    having("SUM(IF(operation_type_id IN (?), 1, 0)) = 0", ids)
  }

  scope :drops_awaiting_pick_up, ->{
    joins("INNER JOIN operations ON containers.id = operations.container_id INNER JOIN operation_types ON operation_types.id = operations.operation_type_id AND operation_types.otype = 'Drop'").
    where("operations.pos = (SELECT max(pos) FROM operations WHERE container_id = containers.id AND operated_at IS NOT NULL ORDER BY pos DESC)").
    order("operations.operated_at DESC")
  }

  scope :without_appt_date, ->{
    where("appt_date IS NULL")
  }

  scope :pending_mileages, ->{
    joins(:operations).
    where("operations.pos != (SELECT max(pos) FROM operations WHERE container_id = containers.id)").
    where("operations.distance IS NULL").
    order("containers.id DESC").
    distinct
  }

  scope :pending_tasks, ->(*ids){
    ids = ids.flatten.compact
    case true
    when ids.empty?
      import_not_regexp = ContainerTask.import.accounting.pluck(:id).map{|id| "task_ids NOT REGEXP '- #{id}\n'"}
      export_not_regexp = ContainerTask.export.accounting.pluck(:id).map{|id| "task_ids NOT REGEXP '- #{id}\n'"}
      where("(containers.type = ? AND (task_ids IS NULL OR #{import_not_regexp.join(' OR ')})) OR (containers.type = ? AND (task_ids IS NULL OR #{export_not_regexp.join(' OR ')}))", 'ImportContainer', 'ExportContainer').
      order("id DESC")
    else
      tmpl = "(containers.type = '%{type}' AND IFNULL(task_ids, '') NOT REGEXP '- %{id}\n')"
      clauses = ContainerTask.where(id: ids).map{|ct| tmpl%{type: "#{ct.ctype}Container", id: ct.id}}.join(" OR ")
      where(clauses).order("id DESC")
    end
  }

  scope :outgated_status, ->{
    select("containers.*, free_outs.days AS free_days").
    joins(:operations).
    joins("INNER JOIN free_outs ON free_outs.ssline_id = containers.ssline_id AND free_outs.container_size_id = containers.container_size_id AND free_outs.container_type_id = containers.container_type_id").
    group("containers.id, free_outs.days").
    having("SUM(IF(operations.operated_at IS NULL, 0, 1)) > 0 AND SUM(IF(operations.operated_at IS NULL, 0, 1)) < COUNT(operations.id)").
    order("containers.id DESC")
  }

  scope :delivered_at_from, ->(date){
    where("containers.delivered_date >= ?", (date.to_datetime rescue nil))
  }
  scope :delivered_at_to, ->(date){
    where("containers.delivered_date < ?", (date.to_datetime + 1 rescue nil))
  }
  scope :created_at_from, ->(date){
    where("containers.created_at >= ?", (date.to_datetime rescue nil))
  }
  scope :created_at_to, ->(date){
    where("containers.created_at < ?", (date.to_datetime + 1 rescue nil))
  }

  scope :operated_at_from, ->(date){
    joins(:operations).
    where("operated_at >= ?", (date.to_datetime rescue nil)).
    group("containers.id")
  }

  scope :operated_at_to, ->(date){
    joins(:operations).
    where("operated_at < ?", (date.to_datetime + 1 rescue nil)).
    group("containers.id")

  }

  scope :keyword_cont, ->(val){
    match = "%#{val.downcase}%"
    likes = %w{container_no ssline_bl_no ssline_booking_no reference_no chassis_no chassis_comment}.map{|name| "lower(#{name}) LIKE ?"}
    where(likes.join(' OR '), *([match]*likes.length))
  }

  scope :chassis_no_within, ->(val){
    nos = val.split(/\n|\,/).map(&:strip).remove_empty.uniq
    sanitized_id_string = nos.map {|no| connection.quote(no) }.join(",")
    regexp_nos = nos.join("|")
    where("chassis_no REGEXP ? OR chassis_comment REGEXP ?", regexp_nos, regexp_nos).
    order("FIELD(chassis_no, #{sanitized_id_string})")
  }

  scope :trucker_id_eq, ->(id){
    joins("LEFT OUTER JOIN container_charges ON container_charges.container_id = containers.id").
    joins("LEFT OUTER JOIN operations ON operations.container_id = containers.id").
    where("container_charges.company_id = ? OR operations.trucker_id = ?", id, id).group("containers.id")
  }

  scope :last_trucker_id_eq, ->(id){
    joins("LEFT OUTER JOIN operations ON operations.container_id = containers.id").
    where("operations.trucker_id = ? AND pos IN (SELECT max(pos) - 1 FROM operations WHERE container_id = containers.id)", id).
    group("containers.id")
  }

  scope :terminal_id_eq, ->(id){
    joins([:operations]).where("operations.company_id = ?", id)
  }

  scope :consignee_name_like, ->(name){
    joins({ operations: [:company, :operation_type] }).where("LOWER(companies.name) LIKE ? AND operation_types.options_from = 'Customer/Consignee'", "%#{name.downcase}%")
  }
  scope :consignee_city_like, ->(city){
    joins({ operations: [:company, :operation_type] }).where("LOWER(companies.address_city) LIKE ? AND operation_types.options_from = 'Customer/Consignee'", "%#{city.downcase}%")
  }
  scope :consignee_state_eq, ->(state=1){
    joins({ operations: [:company, :operation_type] }).where("companies.address_state_id = ? AND operation_types.options_from = 'Customer/Consignee'", state)
  }

  scope :shipper_name_like, ->(name){
    joins({ operations: [:company, :operation_type] }).where("LOWER(companies.name) LIKE ? AND operation_types.options_from = 'Customer/Shipper'", "%#{name.downcase}%")
  }
  scope :shipper_city_like, ->(city){
    joins({ operations: [:company, :operation_type] }).where("LOWER(companies.address_city) LIKE ? AND operation_types.options_from = 'Customer/Shipper'", "%#{city.downcase}%")
  }
  scope :shipper_state_eq, ->(state=1){
    joins({ operations: [:company, :operation_type] }).where("companies.address_state_id = ? AND operation_types.options_from = 'Customer/Shipper'", state)
  }

  scope :incomplete, -> {
    where(edi_complete: false).order("id DESC")
  }

  scope :all_operated, ->{
    joins(:operations).
    group("containers.id").
    having("SUM(IF(operations.operated_at IS NULL, 1, 0)) = 0").
    order("containers.delivered_date ASC")
  }

  scope :chassis_invoices, ->{
    #Accounting::Category-> RAIL CHASSIS or ReceivableCharge: Chassis Fee
    select("
      containers.*,
      SUM(IF(ccs.chargable_type = 'ReceivableCharge' AND ccs.chargable_id = 31, ccs.amount, 0)) AS receivable_chassis,
      SUM(IF(ccs.chargable_type = 'Accounting::Category' AND ccs.chargable_id = 8, ccs.amount, 0)) AS payable_chassis,
      ROUND(SUM(IF(ccs.chargable_type = 'ReceivableCharge' AND ccs.chargable_id = 31, ccs.amount, 0))/20.0) - ROUND(SUM(IF(ccs.chargable_type = 'Accounting::Category' AND ccs.chargable_id = 8, ccs.amount, 0))/17.0) AS chassis_days
    ").
    joins("INNER JOIN container_charges ccs ON containers.id = ccs.container_id").
    where("(ccs.chargable_type = ? AND ccs.chargable_id = ?) OR (ccs.chargable_type = ? AND ccs.chargable_id = ?)", "Accounting::Category", 8, "ReceivableCharge", 31).
    group("containers.id").
    order("containers.id DESC").
    includes(:operations)
  }

  def self.ransackable_scopes(auth=nil)
    [
      :keyword_cont,
      :chassis_no_within,
      :trucker_id_eq,
      :last_trucker_id_eq,
      :terminal_id_eq,
      :delivered_at_from,
      :delivered_at_to,
      :created_at_from,
      :created_at_to,
      :operated_at_from,
      :operated_at_to,
      :consignee_name_like,
      :consignee_city_like,
      :consignee_state_eq,
      :shipper_name_like,
      :shipper_city_like,
      :shipper_state_eq
    ]
  end

  attr_accessor :selected_new_for_invoice, :operation_type_ids, :editor
  serialize :task_ids
  # check the below attributes useful or not
  attr_reader :delete_id
  attr_accessor :customer_change
  #######################################

  alias_method :set_customer, :customer=
  alias_attribute :name, :to_s

  # after_initialize do
  #   generate_pin!(6)
  # end

  def _type
    self.type.gsub(/Container/, '').downcase
  end

  def latest_version!
    @vid = PaperTrail::Version.for_item(self).desc.first.try(:id)
  end

  def street_turn_from
    new_record? ? nil : Container.find_by(street_turn_id: id)
  end

  def has_pod?
    pod_docs.count > 0
  end

  def pod_docs
    ids = operations.select(&:delivery_mark?)
    Image.approved.where("imagable_id IN (?) AND imagable_type = 'Operation'", ids)
  end

  def all_docs
    Image.approved.where("imagable_id IN (?) AND imagable_type = 'Operation'", operation_ids)
  end

  def init_operations
    operation_type_ids.each_with_index do |operation_type_id, index|
      self.operations.build(operation_type_id: operation_type_id, pos: index + 1)
    end if operation_type_ids&&new_record?&&self.to_save.nil?
  end

  def default_chassis_condition
    self.chassis_pickup_with_container = true
    self.chassis_return_with_container = true
  end

  def viewable_operations(user)
    if user.is_trucker?
      ids = operations.for_user(user).inject([]){|ops, op| ops << [op, op.after] }.flatten.compact.uniq.map(&:id)
      operations.where(id: ids)
    else
      operations.for_user(user)
    end
  end

  def all_operated?
    operations.all?(&:operated_at)
  end

  def consignees_or_shippers_info(loaded_companies=nil)
    (loaded_companies || companies).select{|company| ['Consignee', 'Shipper'].include?(company.type) }
  end

  def terminals_info(loaded_companies=nil)
    (loaded_companies || companies).select{|company| ['Terminal'].include?(company.type) }
  end

  def depots_info(loaded_companies=nil)
    (loaded_companies || companies).select{|company| ['Depot'].include?(company.type) }
  end

  def assignable?
    !lock&&operations.map(&:trucker_id).none?
  end

  def assign(trucker)
    operations.reject(&:final?).each{|operation| operation.update_attribute(:trucker_id, trucker.id) }
  end

  def is_export?
    false
  end

  def is_import?
    false
  end

  def task_ids
    super || []
  end

  def toggle_task(tid)
    tid = tid.to_i
    task = ContainerTask.find(tid)
    tids = task_ids || []
    checked = false
    if tids.include?(tid)
      tids.delete(tid)
    else
      tids << tid
      checked = true
    end
    update(task_ids: tids.sort)
    checked
  end

  def pending_task?
    (ContainerTask.send(_type).pluck(:id) - task_ids).present?
  end

  def delete_it=(new_value)
    @delete_it = (new_value == "1") ? true :false
  end

  def to_review
    self.needs_edi_review_was
  end

  def customer_modifiable?
    receivable_line_items.joins(:invoice).where("invoices.company_id = ?", customer_id).empty?
  end

  def customer=(obj)
    case obj
    when Customer
      set_customer(obj)
    when CustomersEmployee
      self.customers_employee_id = obj.id
      set_customer(obj.customer)
    else
      set_customer(nil)
    end
  end

  def get_customer_id
    (customer_id || customers_employee.customer_id) rescue nil
  end

  def to_s
    "#{id} #{container_no.try(:upcase)}".strip
  end

  def lock!
    update_column(:lock, true)
    touch
  end

  def unlock!
    update_column(:lock, false)
    touch
  end

  def receivable_invoices
    receivable_line_items.map(&:invoice).compact
  end

  def payable_invoices
    payable_line_items.map(&:invoice).compact
  end

  def companies
    operations.includes(:company).map(&:company).compact
  end

  def truckers
    operations.map(&:trucker).compact
  end

  def truckers_active
    truckers.map(&:active?).exclude?(false)
  end

  def trucker_names
    truckers.map(&:name).uniq
  end

  def dispatched_count
    operations.map(&:trucker_id).compact.size
  end

  # def generate_pin!(size)
  #   self.pin||= ((p = rand(10**size)).to_s.size==size ) ? p : generate_pin!(size) rescue nil
  # end

  def duplicates
    self.class.where("container_no = ? AND id <> ?", self.container_no, self.id.to_i)
  end

  # If new (rec || pay) charge has been created and an old charge was invoiced for this company, then additional charges for
  # the same company should be in the same invoice; invoice's amount and balance updated.
  # If we have new container with new charges created right away, then those charges will be saved, too.
  # Therefore save_container_charges function will be called after_update
  def save_container_charges
    payable_container_charges.save_changed
    receivable_container_charges.save_changed
    payable_container_charges.set_invoice_if_applicable
    receivable_container_charges.set_invoice_if_applicable
    update_line_items_if_applicable
  end

  def update_line_items_if_applicable
    receivable_line_items.each do |rli|
      rli.update_amount! # Costi - this is not supposed to save the line_item again if no changes done
    end unless receivable_line_items.blank?
    payable_line_items.each do |rli|
      rli.update_amount!
    end unless payable_line_items.blank?
  end

  # Legacy functions - used in invoices - these should use the container_charges_extension
  def charges(accounts, company_id)
    if accounts.to_s =~ /payable/i
      payable_container_charges.charges(company_id)
    elsif accounts.to_s =~ /receivable/i
      receivable_container_charges.charges(company_id)
    end
  end

  def amount(accounts, company_id)
    if accounts.to_s =~ /payable/i
      payable_container_charges.amount(company_id)
    elsif accounts.to_s =~ /receivable/i
      receivable_container_charges.amount(company_id)
    end
  end

  def self.revenues(containers)
    containers.all(:include => :receivable_container_charges).inject(0){|sum, c| sum + c.receivable_container_charges.total_amount}
  end

  def self.costs(containers)
    containers.all(:include => :payable_container_charges).inject(0){|sum, c| sum + c.payable_container_charges.total_amount}
  end

  def self.profit(containers)
    revenues(containers) - costs(containers)
  end

  def payable_payments
    payable_line_items.inject([]){|sum, i| sum + i.line_item_payments.map(&:payment)}
  end

  def receivable_payments
    receivable_line_items.inject([]){|sum, i| sum + i.line_item_payments.map(&:payment)}
  end

  def appt_status
    if appt_date.nil?
      'Pending'
    elsif appt_start.nil? && !appt_confirmed?
      'Proposed'
    end
  end

  def appt_confirmed?
    operations.detect(&:appt_confirmed?).operated_at.present? rescue false
  end

  def appt_scheduled?
    confirmed_by.downcase.strip != AWAITING_CONFIRMATION_COMMENT.downcase
  end

  def confirmed_by
    case true
    when appt_confirmed?
      public_comment.blank? ? RECEIVING_COMMENT : public_comment
    when appt_start.nil?
      AWAITING_CONFIRMATION_COMMENT
    when public_comment.blank?
      RECEIVING_COMMENT
    else
      public_comment
    end
  end

  def payable_invoiced?
    payable_invoices.present?
  end

  def partially_invoiced?
    container_charges.exists? && container_charges.any?{|cc| cc.line_item_id.nil? } && container_charges.any?{|cc| cc.line_item_id.present? }
  end

  def fully_invoiced?
    container_charges.exists? && container_charges.none?{|cc| cc.line_item_id.nil? }
  end

  def been_paid?
    container_charges.exists? && container_charges.any?{|cc| cc.line_item.try(:paid?) }
  end

  def fully_paid?
    container_charges.exists? && container_charges.all?{|cc| cc.line_item.fully_paid? }
  end

  def pre_alert?
    !confirmed
  end

  # A container can be deleted by customer if it's pre alert, by admin if it hasn't been delivered yet, and
  # by superadmin if it has been delivered or is partially / fully invoiced. If container is partially / fully
  # paid, it cannot be deleted at all. To perform destroy action on it, you must delete all payments first.
  # Note: invoices can't be deleted either if they have payments.
  def destroy_by(user)
    if been_paid?
      errors.add(:base, "It has partially or full paid payment(s)")
      return false
    end

    if street_turn
      errors.add(:base, "It associated with street turn to Container ID #{street_turn_id}.")
      return false
    end

    if street_turn_from
      errors.add(:base, "It associated with street turn from Container ID #{street_turn_from.id}.")
      return false
    end

    if operations.none?(&:removable?)
      errors.add(:base, "Some associated operation is not removable.")
      return false
    end

    if destroy_by_customer?(user) || destroy_by_admin?(user) || destroy_by_superadmin?(user)
      OrderMailer.notify_order_cancelled(id).deliver_now unless pending_receivable
      destroy
    else
      errors.add(:base, "Container status '#{self.status}' does not allow it.")
      return false
    end
  end

  def destroy_by_customer?(user)
    user.is_customer? && pre_alert?
  end

  def destroy_by_admin?(user)
    user.is_admin? && (pre_alert? || confirmed?)
    # ["pre alert", "late", "confirmed"].include?(self.status)
  end

  def destroy_by_superadmin?(user)
    user.is_superadmin? && (pre_alert? || confirmed? || delivered? || partially_invoiced? || fully_invoiced?)
      # ["pre alert", "confirmed", "late", "delivered", "partially invoiced", "fully invoiced"].include?(self.status)
  end

  def self.build_similar_to(similar)
    container = new(
      hub_id: similar.hub_id,
      customer_id: similar.customer_id,
      customers_employee_id: similar.customers_employee_id,
      container_size_id: similar.container_size_id,
      container_type_id: similar.container_type_id,
      ssline: similar.ssline,
      reference_no: similar.reference_no,
      commodity: similar.commodity,
      terminal_eta: similar.terminal_eta,
      chassis_pickup_with_container: similar.chassis_pickup_with_container,
      chassis_return_with_container: similar.chassis_return_with_container,
      chassis_pickup_company_id: similar.chassis_pickup_company_id,
      chassis_return_company_id: similar.chassis_return_company_id
    )
    container.operations = similar.operations.map(&:dup)
    container
  end

  def siblings
    self.class.where("containers.customer_id = ? AND containers.id <> ? AND containers.reference_no = ? AND containers.reference_no <> ?", customer_id, id, reference_no, "")
  end

  def self.is_daily?(expected_result)
    expected_result == "daily"
  end

  def self.is_monthly?(expected_result)
    expected_result == "monthly"
  end

  def self.retrieve_data(filter, daily_or_monthly)
    containers = Hash.new
    containers[:import] = Array.new
    containers[:export] = Array.new
    containers[:interval] = Array.new
    start_date = filter.from
    period = filter.from.months_to(filter.to) + 1 if is_monthly?(daily_or_monthly)
    if is_daily?(daily_or_monthly)
      filter.to = filter.from + 30.days if filter.from.days_to(filter.to) > 30
      period = filter.from.days_to(filter.to) + 1
    end

    for add_number_of in (1..period) do
      if is_daily?(daily_or_monthly)
        filter.from = ((start_date + add_number_of.days) - 1.day).to_date
        filter.to = filter.from
        containers[:interval] << filter.from.to_date
      elsif is_monthly?(daily_or_monthly)
        filter.from = ((start_date + add_number_of.months) - 1.month).beginning_of_month.to_date
        filter.to = filter.from.end_of_month.to_date
        containers[:interval] << filter.from.to_date
      end
      containers[:import] << ImportContainer.filter(filter).count
      containers[:export] << ExportContainer.filter(filter).count
    end
    filter.from = start_date
    containers
  end

  def self.compute_volume(filter, range)
    containers = retrieve_data(filter, range)
    result = {:import => [], :export => []}
    containers[:interval].each_with_index do |value, index|
      result[:import] << [value, containers[:import][index]]
      result[:export] << [value, containers[:export][index]]
    end
    result
  end

  def self.mileages_stats(params={})
    step = Analysis::BaseRate.mile_step
    Container.search(params).result.map do |container|
      meters = container.mileage
      meters||= container.customer_mileage
      (meters/METER_TO_MILE*2).round(0)
    end.compact.sort.inject({}) do |h, mile|
      mile = (mile/step).ceil*step
      h[mile]||= 0
      h[mile]+= 1
      h
    end.sort
  end

  def self.the_very_first
    delivered.order('delivered_date ASC').first
  end

  def warnings
    @warnings = Hash.new
    #& to review
    # if trucker && payable_container_charges.base_rate
    #   if trucker != payable_container_charges.base_rate.company
    #     @warnings[:trucker_id] = ' is not in the payable base rate.'
    #   end
    # end
    if customer && receivable_container_charges.base_rate
      if customer != receivable_container_charges.base_rate.company
        @warnings[:customer_id] = ' is not in the receivable base rate.'
      end
    end

    @warnings
  end

  # returns an array of hashes with xml attributes for each container
  def self.array_of_xml_attributes(containers)
    containers.map(&:xml_attributes)
  end


  # returns hash of xml attributes for a container
  def xml_attributes
    all_attr = self.attributes # hash
    requested_attr = Hash.new
    XML_ATTRIBUTES.each do |attr|
      if all_attr.keys.include?(attr)
        case attr
        when "ssline_id" then requested_attr.merge!({"ssline_name" => self.ssline.name})
        when "container_size_id" then requested_attr.merge!({"container_size" => self.container_size.name})
        when "container_type_id" then requested_attr.merge!({"container_type" => self.container_type.name})
        when "appt_date" then requested_attr.merge!({"appt_date" => (self.appt_date && self.appt_start ? appt_range(self, true) : nil )})
        else requested_attr.merge!({attr => all_attr[attr]})
        end
      end
    end

    requested_attr.merge!({"remote_id" => self.id})
    requested_attr
  end

  def raw_profit
    self.receivable_container_charges.total_amount - self.payable_container_charges.total_amount
  end

  def self.pre_alerts(user)
    self.prealert_assocs.unconfirmed.for_user(user).order('ISNULL(rail_lfd) asc, rail_lfd asc, ISNULL(terminal_eta) asc, terminal_eta asc')
  end

  def self.format_time(time)
    time.strftime("%l:%M%p").lstrip
  end

  def chassis_pickup_required?
    !chassis_pickup_with_container.is_a?(NilClass)
  end

  def chassis_return_required?
    !chassis_return_with_container.is_a?(NilClass)
  end

  def nullify_chassis_info
    if chassis_pickup_with_container
      self.chassis_pickup_company_id = nil
      self.chassis_pickup_at = nil
    end
    if chassis_return_with_container
      self.chassis_return_company_id = nil
      self.chassis_return_at = nil
    end
  end

  def nullify_appt_end
    self.appt_end = nil unless self.appt_is_range.to_boolean
  end

  def set_appt_is_range
    self.appt_is_range = self.appt_start.present? && self.appt_end.present? ? "true" : "false" rescue nil
  end

  def convert_weight
    if self.weight_is_metric.to_boolean
      self.weight = self.weight.to_f * 2.20462262
      self.weight_is_metric = nil
    end
    self.weight = self.weight.round(2) if self.weight
  end

  def accept_container
    self.customer.edi_provider.accept_container(self)
    self.update_attribute(:needs_edi_review, false)
  end

  def reject_container
    self.customer.edi_provider.reject_container(self)
    self.destroy_by(User.authenticated_user).is_a?(Container)
  end

  def send_214_scheduled
    if self.customer.use_edi? &&
       self.confirmed? &&
       self.changes.keys.include?("public_comment") &&
       self.appt_start.present?
       self.customer.edi_provider.enqueue(214, {container_id: self.id, event_type: :scheduled})
    end
  end

  def size
    "#{self.container_size.name} #{self.container_type.name}" rescue "N/A"
  end

  def final_appt
    case true
    when appt_end.present?
      Time.zone.parse(appt_date.ymd + ' ' + appt_end.strftime('%H:%M'))
    when appt_start.present?
      Time.zone.parse(appt_date.ymd + ' ' + appt_start.strftime('%H:%M'))
    else
      appt_date.end_of_day
    end
  rescue =>ex
    nil
  end

  def appointment(display_date=true)
    datas = []
    if appt_date.present?
      datas << appt_date.strftime("%F") if display_date
      if appt_start.present?
        datas << "btwn" if appt_end.present?
        datas << Container.format_time(appt_start)
        datas << "and" if appt_end.present?
        datas << Container.format_time(appt_end) if appt_end.present?
      end
    end
    datas.join(' ').strip
  end

  def is_reefer?
    self.container_type.name =~/RF/
  end

  def to_rail_bill?
    false
  end

  def to_equipment_release?
    false
  end

  def self.remedy_mileages
    Container.pending_mileages.limit(100).each_with_index do |container, index|
      delay = ((index+1)*3).seconds
      container.build_scheduled_trips(delay)
    end
  end

  def schedule_trips
    if Container.routes_changed
      build_scheduled_trips
      Container.routes_changed = false
    end
  end

  def recalculate_mileages
    Container.routes_changed = true
    operations.update_all({ distance: nil, yard_distance: nil})
    schedule_trips
  end

  def be_linked?
    Operation.where("linked_id in (?)", operations.map(&:id)).present?
  end

  def be_linker?
    operations.any?(&:linked_id)
  end

  def chains
    dms = DriverMileSegment.new(self)
    dms.build_linkeds
    dms.map(&:operations).flatten.uniq.map(&:container).uniq
  end

  def chains_without_mileage
    chains.map(&:operations).flatten.reject(&:final?).reject{|o| o.distance.to_f > 0 }.map(&:container).uniq
  end

  def calculate_quote(user)
    return "The linker/linked container #{chains_without_mileage.map(&:id).join(", ")} is lack of mileage." if chains_without_mileage.present?
    chains.map do |container|
      unless container.lock?
        container.update_column(:quoted, true)
        container.touch
        ContainerQuote.new(container, user).quotes.reject(&:preset).map do |quote|
          quote.save_charge
        end
      end
    end.flatten.compact.map { |hash| hash[:error] }.compact.uniq.join("; ")
  end

  def preview_quote(user)
    Container.transaction do
      operations.map{|o| o.recipient_id = nil } # avoid send email out
      save(validate: false)
      reasonable_truckers
      ContainerQuote.new(self, user).quotes.reject(&:preset).each do |quote|
        if quote.operation.trucker_id
          self.payable_container_charges.build(quote.base_rate_charge_attrs) if quote.base_rate_fee.to_f > 0
          self.payable_container_charges.build(quote.fuel_surcharge_charge_attrs)  if quote.fuel_amount.to_f > 0
          self.payable_container_charges.build(quote.tolls_fee_charge_attrs) if quote.tolls_fee.to_f > 0
          self.payable_container_charges.build(quote.toll_surcharge_charge_attrs) if quote.toll_surcharge.to_f > 0
        end
      end if errors[:base].empty?
      raise ActiveRecord::Rollback
    end
  end

  def notify_truckers
    dms = DriverMileSegment.new(self)
    dms.each do |segment|
      segment.operations.first.notify(true)
    end
  end

  def require_prepull_charge?
    (operations.includes(:container).select{|o| o.prepull_trip?}.map(&:id) - payable_container_charges.where(chargable_id: PayableCharge.prepull.id).where(chargable_type: "PayableCharge").map(&:operation_id)).present?
  end

  def require_prepull_trucker?
    operations.joins(:operation_type).where("operations.trucker_id IS NULL AND operation_types.otype = 'Prepull'").exists?
  end

  def live_load?
    operations.map(&:is_drop?).exclude?(true)
  end

  def with_prepull?
    operations.map(&:is_prepull?).include?(true)
  end

  def dropped_date
    operations.detect(&:is_drop?).try(:view_operated_at)
  end

  def build_scheduled_trips(delay=1.seconds)
    ScheduleTripWorker.perform_in(delay, id)
  end

  def customer_mileage
    companies = operations.map(&:company).compact
    rail_road = terminals_info(companies).map(&:rail_road).first
    dest_address = consignees_or_shippers_info(companies).first.address
    meters = GoogleMap.distance(rail_road.lan_lon.join(','), dest_address).to_i
    update_column(:mileage, meters) if persisted? && meters > 0
    meters
  end

  def calculate_distances
    self.reload.operations.each do |operation|
      from = operation.company.address rescue nil
      to = operation.after.company.address rescue nil
      to_yard = operation.yard.address rescue nil
      if from
        operation.update_column(:distance, GoogleMap.distance(from, to)) if to
        operation.update_column(:yard_distance, GoogleMap.distance(from, to_yard)) if to_yard&&operation.is_drop?
        operation.touch
      end
    end
  end

  def mileage_with_appt
    dms = DriverMileSegment.new(self.reload)
    dms.build_linkeds
    dms.each do |segment|
      first = segment.operations.first
      actual_appt = first.is_drop? ? first.appt : first.container.appt_date
      segment.operations.each do |operation|
        operation.set_actual_appt(actual_appt)
        operation.set_complete_mileage(operation.leg_miles)
        operation.set_pickup_appt(actual_appt.try(:beginning_of_day)) if (operation.container_id!= self.id)&&operation.is_drop?
        operation.touch
      end
    end
  end

  def sort_operations
    operations.each_with_index do |operation, index|
      operation.update_column(:pos, index + 1)
    end
  end

  def mileages_ready?
    operations.any?(&:distance)
  end

  def operations_editable?
    @operations_editable||= no_payable_invoice_for_trucker?
  end

  def no_payable_invoice_for_trucker?
    payable_line_items.joins({invoice: :company}).where("companies.type = 'Trucker'").empty?
  end

  def save_payable_container_charges!(attrs={})
    Container.transaction do
      attrs.each{|_, _attrs| _attrs.merge!(auto_save: true) }
      payable_container_charges.joins(:company).where("companies.type = 'Trucker'").destroy_all
      payable_container_charges.new_collection(attrs)
      if payable_container_charges.map(&:valid?).exclude?(false)
        save(validate: false)
      else
        raise 'Invalid payable charges'
      end
    end
  end

  def send_truckers_notification
    overlap = changed.map(&:to_sym) & SIGNIFICANT_CONTAINER_FIELDS.keys
    overlap.delete(:appt_start) if same_appt_start?
    overlap.delete(:appt_end) if same_appt_end?
    unless overlap.empty?
      hash_changed = {}
      attrs = changed_attributes.select{|key, value| overlap.include?(key.to_sym)}
      old = self.dup
      old.attributes = attrs
      overlap.each do |key|
        name, diff = SIGNIFICANT_CONTAINER_FIELDS[key].call(old, self)
        hash_changed[name] = diff
      end
      self.operations.select{ |operation| operation.notified? }.map(&:trucker_id).uniq.each do |trucker_id|
        OrderMailer.delay.notify_trucker_container_updated(id, trucker_id, hash_changed)
      end
    end
  end

  def check_duplicate_payable_container_charges
    base_rate_ids = PayableCharge.where(name: UNIQ_CHARGES_PER_CONTAINER).map(&:id)
    errors.add(:base, DUP_PAYABLE_CHARGES_ERROR) if payable_container_charges.select{|pcc|
      pcc.chargable_type == 'PayableCharge'
    }.reject{|pcc|
      pcc.uid.nil? || base_rate_ids.exclude?(pcc.chargable_id)
    }.group_by(&:uid).values.any?{|value|
      value.length > 1
    }
  end

  def check_mandatory_charges
    if !pending_receivable && !lock? && editor.try(:is_admin?)
      mandatory_group = ReceivableCharge.mandatory.group_by(&:mandatory_sign)
      if mandatory_group.keys.size > 0
        chargable_ids = receivable_container_charges.select{|rcc| rcc.chargable_type == "ReceivableCharge" }.map(&:chargable_id)
        charges = ReceivableCharge.mandatory.where(id: chargable_ids)
        grouped = charges.group_by(&:mandatory_sign)
        case grouped.keys.size
        when 0
          grouped_info = mandatory_group.values.map{|group| group.map(&:name).join(', ')}.join('; ')
          errors.add(:base, "Must enter one group of mandatory charges: #{grouped_info}")
        when 1
          sign = grouped.keys.first
          diff = mandatory_group[sign] - charges
          errors.add(:base, "You still need other mandatory charge(s): #{diff.map(&:name).join(', ')}") if diff.present?
        else
          grouped_info = mandatory_group.values.map{|group| group.map(&:name).join(', ')}.join('; ')
          errors.add(:base, "You just need one group of mandatory charges: #{grouped_info}")
        end
      end
    end
  end

  def find_or_init_task_comment(container_task_id)
    task_comments.where(container_task_id: container_task_id).first_or_initialize
  end

  def task_comment(container_task_id)
    task_comments.detect{|tc| tc.container_task_id == container_task_id}
  end

  def done_tasks?(account)
    (ContainerTask.send(_type).send(account).pluck(:id) - task_ids).empty?
  end

  def check_connection
    update_column(:connected, false)
    update_column(:connected, true) if be_linker?
    update_column(:connected, true) if be_linked?
  end

  def pick_up_date
    operations.first.try(:view_operated_at)
  end

  def picked_up?
    operations.first.try(:operated_at_confirmed?)
  end

  def returned_date
    operations.return_mark.first.try(:operated_at)
  end

  def returned?
    operations.return_mark.first.try(:operated_at_confirmed?)
  end

  def pending_receivable?
    new_record? || pending_receivable
  end

  def save_as!(type, user)
    case type
    when /pending/i
      self.pending_receivable = true
    when /confirmed/i
      self.confirmed = true
      self.pending_receivable = false
    else # default: unconfirmed
      self.confirmed = false
      self.pending_receivable = false
    end
    self.editor = user
    save!
    reload
    if !order_emailed&&!pending_receivable
      if needs_edi_review
        accept_container
      else
        OrderMailer.delay_for(1.minute).notify_contact_order_created(id)
      end
      OrderMailer.delay.notify_dispatch_order_created(id) if user.is_customer?
      update_column(:order_emailed, true)
    end
    touch
  end

  def needs_edi_review=(value)
    if value
      self[:needs_edi_review] = self.pending_receivable = true
      self.order_emailed = false
    else
      self[:needs_edi_review] = false
    end
  end

  def assign_interchange_id
    self.interchange_receiver_id = hub.hub_interchanges.where(customer_id: customer.id).first.try(:edi)
  end

  def pending_j1s?(user)
    J1s.pending_by?(user, id)
  end

  def container_no_updatable_by?(user)
    user.is_admin?
  end

  def chassis_no_updatable_by?(user)
    return true if user.is_admin?
    chassis_no.blank? or has_alter_request?(:chassis_no)
  end

  def chassis_pickup_at_updatable_by?(user)
    return true if user.is_admin?
    chassis_pickup_at.blank? or has_alter_request?(:chassis_pickup_at)
  end

  def chassis_return_at_updatable_by?(user)
    return true if user.is_admin?
    chassis_return_at.blank? or has_alter_request?(:chassis_return_at)
  end

  def default_chassis_pickup_return
    self.chassis_pickup_with_container = true
    self.chassis_return_with_container = true
    self.chassis_pickup_company_id = nil
    self.chassis_return_company_id = nil
  end

  def self.policy_class
    ContainerPolicy
  end

  private :destroy # Only call destroy_by(user)

  private
    def invalid_appt_times?
      if appt_is_range.to_boolean
        appt_end.blank? || appt_start.blank? || appt_end.hm < appt_start.hm
      end
    end

    def same_appt_start?
      appt_start_was.hm == appt_start.hm rescue false
    end

    def same_appt_end?
      appt_end_was.hm == appt_end.hm rescue false
    end

    def notify_dispatcher
      OrderMailer.delay_for(1.minute).notify_dispatch_new_edi_order(id) if needs_edi_review
    end

    def finalize_operation
      self.reload.operations.last.finalize rescue nil
    end

    def count_operations
      update_column(:operations_count, operations.size)
    end

    def set_est_ops_date
      update_column(:est_ops_date, appt_date) if appt_date_was == est_ops_date
    end

    def init_uuid
      self.uuid = SecureRandom.hex(6)
    end

end
