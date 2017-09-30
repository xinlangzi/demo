class CustomersEmployee < User
  belongs_to :customer
  has_many :containers

  validates :customer_id, presence: true
  validates :name, uniqueness: { scope: [:deleted_at, :customer_id] }

  scope :active, ->{ where(deleted_at: nil) }
  scope :for_user,  ->(user){
    case user.class.to_s
    when 'CustomersEmployee'
      where("customer_id = ?", user.customer_id)
    when 'SuperAdmin', 'Admin'
      all
    else
      raise "Authentication / Access error for #{user.class}"
    end
  }

  after_create :assign_customer_role

  def assign_customer_role
    self.roles << Role.find_by(name: "Customer")
  end

  def self.default_rights
    Role.find_by(name: 'Customer').default_rights
  end

  def is_customer?
    true
  end

  def employer
    customer
  end

  def self.get_names_and_ids(customer=nil)
    customer.get_employees_names_and_ids rescue Array.new
  end

end
