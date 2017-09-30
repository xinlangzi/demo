class OperationType < ApplicationRecord
  has_many :operations, dependent: :restrict_with_exception
  belongs_to :email_template_for_set_date, class_name: 'OperationEmail', foreign_key: :set_date_email_id
  belongs_to :email_template_for_remove_date, class_name: 'OperationEmail', foreign_key: :reset_date_email_id
  validates :name, presence: true, uniqueness: {scope: :container_type}
  validates :options_from, presence: true
  validates :date_format, presence: true
  validates :set_date_email_id, presence: true, if: Proc.new{|operation_type| operation_type.email_when_set_date}
  validates :reset_date_email_id, presence: true, if: Proc.new{|operation_type| operation_type.email_when_remove_date}

  DATE_FORMATS = ["Date", "DateTime"].freeze
  OPTIONS = ["Customer/Consignee", "Customer/Shipper", "Customer/Employee", "Ssline/Depot", "Terminal", "Yard"].freeze
  RECIPIENTS = ["None", "All", "Customer", "Trucker"].freeze
  CONTAINER_TYPES = ["Import/Export", "Import", "Export"].freeze
  OTYPES = ["None", "Delivery", "Drop", "Prepull", "StreetTurn"].freeze
  CONSIGNEE_WARNING = "Select Customer to see consignees"
  SHIPPER_WARNING = "Select Customer to see shippers"
  DEPOT_WARNING = "Select Steamship line to see depots"


  scope :default, ->{ where(default: true) }
  scope :export, ->{ where("container_type like ?", "%Export%") }
  scope :import, ->{ where("container_type like ?", "%Import%") }
  scope :required_docs, ->{ where(required_docs: true) }

  before_destroy :can_destroy?

  def self.sub_marks(mark)
    OPTIONS.collect{|option|
      option.downcase.split('/').last if option.downcase=~/#{mark}/
    }.compact
  end

  def self.build_options(hub, mark, id)
    sub_marks(mark).inject({}) do |selects, sub_mark|
      operation_type = OperationType.new(options_from: sub_mark)
      selects[sub_mark.to_sym]||={}
      selects[sub_mark.to_sym][:options] = operation_type.options(hub, id)
      selects[sub_mark.to_sym][:warning] = operation_type.warning(hub, id)
      selects
    end
  end

  def is_prepull?
    self.otype == 'Prepull'
  end

  def is_drop?
    self.otype == 'Drop'
  end

  def is_streetturn?
    self.otype == 'StreetTurn'
  end

  def time_required?
    self.date_format=='DateTime'
  end

  def options(hub, id=nil)
    case self.mark
    when /terminal/
      hub.terminals.to_a
    when /yard/
      hub.yards.to_a
    when /shipper/
      hub.shippers.where(customer_id: id).to_a rescue []
    when /depot/
      hub.depots.where(ssline_id: id).to_a rescue []
    when /consignee/
      hub.consignees.where(customer_id: id).to_a rescue []
    when /employee/
      Customer.find(id).employees.to_a rescue []
    else
      []
    end
  end

  def warning(hub, id=nil)
    warn = nil
    case self.mark
    when /shipper/
      warn = SHIPPER_WARNING if self.options(hub, id).empty?
    when /depot/
      warn = DEPOT_WARNING if self.options(hub, id).empty?
    when /consignee/
      warn = CONSIGNEE_WARNING if self.options(hub, id).empty?
    else
    end
    warn
  end

  def related_id(container)
    cid = nil
    case self.mark
    when /depot/
      cid = container.ssline_id
    when /consignee/
      cid = container.get_customer_id
    when /shipper/
      cid = container.get_customer_id
    else
    end
    cid
  end

  def mark
    self.options_from.strip.split('/').last.downcase
  end

  def can_destroy?
    self.operations.empty?
  end

  def is_depot?
    self.options_from == 'Ssline/Depot'
  end

  def is_terminal?
    self.options_from == 'Terminal'
  end

  def is_customer?
    self.options_from =~/\ACustomer/
  end

  def is_consignee?
    self.options_from == 'Customer/Consignee'
  end

  def is_shipper?
    self.options_from == 'Customer/Shipper'
  end
end
