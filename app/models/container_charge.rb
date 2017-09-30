class ContainerCharge < ApplicationRecord
  has_paper_trail only: [:amount, :chargable_id, :company_id, :details]

  belongs_to :container, touch: true
  belongs_to :company
  belongs_to :line_item
  belongs_to :chargable, polymorphic: true
  has_many   :line_item_payments, through: :line_item

  # Some receivable charges have to have the default the container's Ssline: "Lift Fee" and "Chassis Split"
  SSLINE_CHARGES = ["Lift Fee", "Chassis Split"]

  PAPER_TRAIL_TRANSLATION ={
    "company_id" => Proc.new{|id| Company.find(id).to_s},
    "chargable_id" => Proc.new{|id| Charge.find(id).name},
    "operation_id" => Proc.new{|id| Operation.find(id) }
  }

  validates :amount, :numericality => true
  validates :chargable_id, :chargable_type, presence: true
  validates :details, presence: { message: "can't be blank for 'Other' charges" }, if: Proc.new{|cc| cc.chargable && cc.chargable.is_a?(Charge) && cc.chargable.name == 'Other' }
  validates :company_id, presence: true
  validates :container, presence: true
  validates :container_id, presence: true, if: Proc.new{|cc| !cc.container.new_record? }
  
  validates_each :line_item_id, allow_nil: true do |record, attr, value|
    if !record.container.delivered?
      record.errors.add attr, 'Container cannot have an invoice if is not delivered'
    end
  end

  validate do
    errors.add(:base, "You can not have an object of the base class, Container Charge") unless self.class != ContainerCharge
    errors.add(:amount, "cannot be modified if invoice has been paid") if amount_changed? && line_item.try(:paid?)
  end

  #solve the issue: Mysql2::Error: Unknown column 'NaN'
  before_validation do
    self.amount = amount.to_s.to_f
  end

  scope :auto_saved, ->{ where(auto_save: true) }
  scope :payable, ->{ joins("INNER JOIN charges ON charges.id = container_charges.chargable_id AND container_charges.chargable_type = 'PayableCharge'") }
  scope :receivable, ->{ joins("INNER JOIN charges ON charges.id = container_charges.chargable_id  AND container_charges.chargable_type = 'ReceivableCharge'") }
  scope :for_company, ->(company_id){ where(company_id: company_id) }
  scope :total, ->{ select("ifnull(sum(container_charges.amount), 0) AS total") }
  scope :performance, ->{
    joins(:company).
    select('container_charges.container_id AS container_id, container_charges.amount AS amount, container_charges.company_id AS company_id, companies.name AS company_name, container_charges.chargable_type AS chargable_type, container_charges.chargable_id AS chargable_id, concat(container_charges.chargable_type, "-", container_charges.chargable_id) AS chargable')
  }

  scope :health_indicator, ->{
    joins(:company).
    select("container_charges.*, companies.name AS company_name")
  }

  after_create :find_myself_a_new_line_item!
  after_update :update_line_item
  after_destroy :delete_line_item_if_last

  attr_accessor :uid

  delegate :name, to: :chargable

  # use to associate the parent
  def audit_parent
    self.container
  end

  def preset?
    chargable.try(:preset)
  end

  # If one of my siblings has a line_item, I will set that same line_item for myself and
  # I will update the amount on the line_item
  def find_myself_a_new_line_item!
    if !siblings.blank?&&(cc_found = siblings.detect{|cc| cc.line_item_id})
      reload.update(line_item: cc_found.line_item) # MUST reload to reset "changed"
      line_item.update_amount!
    # else
    #   save unless new_record? #why save again
    end
  end

  # add new charge to same company -> find a sibling, set line item id, save and update li amount
  # delete charge from same company -> (update_collection) destroy the charge and update li amount
  # modif amount for same company -> update li amount
  # change company from old to new:
  # new company has li but old doesn't -> set li id to new, save, update new company's li amount
  # old has li but new doesn't -> set li id to nil, save, update old li amount
  # old and new charges both uninvoiced -> do nothing
  # old and new both invoiced -> set li to new company's li, save, update old li amount (-), update new li amount (+)
  # the problem is that after_update is being called every time saving occurs:
  # new charge created, we're trying to set the line item, but saving it will send to after_update action
  # which will call set line item again.
  def update_line_item
    if line_item && !changed.include?('line_item_id')
      if changed.include?('company_id') && !changes['company_id'].first.blank? # only if there was a company that we're moving the charge from.
        # if the new company has an line_item, add to that line_item
        # if not, nullify the line_item_id
        old_line_item = line_item
        self.line_item = nil
        find_myself_a_new_line_item!
        if old_line_item.container_charges.blank?
          old_line_item.to_destroy
        else
          old_line_item.update_amount!
        end
      else
        line_item.update_amount! # we just changed the amount...
      end
    end
  end

  before_destroy do
    self.reload rescue nil # very important after destory to make sure line_item is still there
  end

  def delete_line_item_if_last
    line_item.to_destroy if line_item #make sure that we delete the line item if it remains without charges
  end

  def siblings
    container.send(self.class.to_s.tableize).charges(company_id).reject{|cc| cc == self}
  end

  def can_be_modified?
    line_item&&(line_item.balance < line_item.amount) ? false : true
  end


  def payable?
    self.class.to_s =~ /Payable/
  end

  def receivable?
    self.class.to_s =~ /Receivable/
  end

  def self.compare2(one, two)
    one.chargable == two.chargable &&
    one.amount == two.amount &&
    one.details == two.details
  end

  def key=(new_key)
    @key = new_key unless new_key.blank?
  end

  def generate_key!(size=12)
    @key = -rand(10**size)
  end

  def key
    if id
      @key = id
    else
      @key ||= generate_key!
    end
    @key
  end

  # set by the form. It's an input that specifies if I want to delete this charge.
  def delete_it=(delete_it_string)
    @delete_it = (delete_it_string == "1") ? true : false
  end

  attr_reader :delete_it

  def self.total_amount
    self.all.inject(0){|sum, cc| sum + cc.amount}
  end

  # JOINING on container_operations might not be necessary, because if it has a line item, it should be delivered
  def self.uninvoiced_companies_id(accounts)
    type = "#{accounts.to_s.singularize.capitalize}ContainerCharge"
    case accounts.to_s.singularize.downcase.to_sym
    when :receivable
      joins(:container).
      where("line_item_id IS NULL AND container_charges.type = ? AND containers.delivered = ?", type, true).
      select(:company_id).distinct
    else
      container_ids = Container.uninvoiced_cached(accounts).select(:id).distinct
      where("container_charges.line_item_id IS NULL AND container_charges.type = ? AND container_charges.container_id in (?)", type, container_ids).
      select(:company_id).distinct
    end
  end

  def default_amount
    chargable.by_hub(container.hub).try(:amount).to_f rescue 0
  end

  def set_default_fields
    if chargable && container
      if kind_of?(ReceivableContainerCharge) && SSLINE_CHARGES.include?(chargable.name) && container.ssline.present?
        self.company = container.ssline
      end
      if chargable.name == 'Fuel Surcharge'
        self.details = chargable.by_hub(container.hub).percentage.to_s + '%' rescue nil
      end
    end
    self.amount||= default_amount
  end

  def mark_as_readonly?
    auto_save || company.try(:inactive?)
  end

  def road_side_service?
    !!chargable.try(:road_side_service)
  end

  private
end
