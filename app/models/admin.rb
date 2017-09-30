class Admin < User

  has_many :invoices
  has_many :audit_charges, foreign_key: :assignee_id, dependent: :nullify
  has_and_belongs_to_many :hubs, join_table: "companies_hubs", foreign_key: :company_id

  after_create :assign_roles # bookkeeper & dispatcher

  def assign_roles
    self.roles << Role.find_by(name: "Dispatcher")
    self.roles << Role.find_by(name: "Bookkeeper")
  end

  def self.default_rights
     Role.find_by(name: 'Admin').default_rights
  end

  def is_admin?
    true
  end

  def containers
    Container.all
  end

  require_dependency 'super_admin'
end
