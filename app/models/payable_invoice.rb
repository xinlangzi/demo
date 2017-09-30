class PayableInvoice < ContainerInvoice
  attr_reader :auto_number

  has_many :line_items, class_name: 'PayableLineItem', foreign_key: :invoice_id, dependent: :destroy

  validates :number, presence: true , unless: :auto_number
  validates :number, uniqueness: { scope: [:company_id], case_sensitive: false }
  validates_date :issue_date

  validates_each :auto_number do |record, attribute, value|
    if !value && record.generate_multiple.to_boolean
      record.errors.add attribute, " must be selected to generate unique invoice number if you want to generate one invoice per container."
    end
  end

  after_create :set_auto_number, if: :auto_number

  alias_attribute :date, :issue_date

  def auto_number=(value)
    @auto_number = value.to_boolean
  end

  def bill_to
    Owner.first
  end

  def bill_from
    self.company
  end

  def needs_adjustments?
    company.instance_of?(Trucker)
  end

  def good_day_log?
    DayLog.good_week?(company, issue_date)
  end

  def ready_to_pay?
    ## Assume today is Monday, driver's invoice was created on last Saturday.
    ## If 1 week pay, then it's ready to pay today.              Count of Saturday(1)
    ## If 2 weeks pay, then it will be ready to pay next Monday. Count of Saturday(2)
    (issue_date..Date.today).map(&:cwday).count(6) >= company.week_pay.to_i
  end

  def pending_j1s?
    ids = line_items.where("balance > 0").map(&:container_id)
    J1s.pending_by?(company, ids)
  end

  def icon
    "fa fa-money red"
  end
  private
    def set_auto_number
      reload.update(number: "auto#{id}")
    end
end
