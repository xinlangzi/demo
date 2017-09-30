class Customer < Company
  has_many :consignees, dependent: :destroy
  has_many :shippers, dependent: :destroy
  has_many :quotes, dependent: :destroy
  has_many :spot_quotes, :dependent => :nullify
  has_many :containers, ->{ order('containers.created_at DESC') }
  has_many :import_containers, ->{ order('containers.created_at DESC') }
  has_many :export_containers, ->{ order('containers.created_at DESC') }
  has_many :employees, ->{ order('name ASC') }, class_name: 'CustomersEmployee', dependent: :destroy
  belongs_to :edi_provider, class_name: "Edi::Provider"

  enum invoice_j1s: { all_j1s: 0, pod_j1s: 1 }

  validates :name, :address_state_id, presence: true
  validates :name, uniqueness: { scope: [:deleted_at] }
  # validates :address_country, inclusion: { in: %w(USA Canada), message: "should be USA or Canada." }

  scope :group_options, ->{ order('name ASC') }
  scope :uses_edi, ->{ where(use_edi: true) }

  alias_attribute :users, :employees

  def mark_as_deleted
    transaction {
      if super
        self.shippers.each {|s| s.mark_as_deleted}
        self.consignees.each {|c| c.mark_as_deleted}
        self.employees {|c| c.mark_as_deleted}
      end
    }
  end

  def get_employees_names_and_ids
    self.employees.active.collect {|e| [e.name, e.id] } || Array.new
  end

  def send_invoice_by_edi?
    self.use_edi && self.edi_provider.try(:send_invoice_by_edi?)
  end

  def invoice_footer
    self.edi_provider.invoice_footer rescue ""
  end
end
