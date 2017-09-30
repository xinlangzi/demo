class CheckTemplate < ApplicationRecord
  belongs_to :admin

  validates :name, presence: true, uniqueness: {case_sensitive: false}
  validates :admin_id, :rtf, presence: true, on: :create
  validates_format_of :rtf, :with => /@check_details\[:check_date\]/, :on => :create, :message => "check_date is invalid"
  validates_format_of :rtf, :with => /@check_details\[:check_amount\]/, :on => :create, :message => "check_amount is invalid"
  validates_format_of :rtf, :with => /@check_details\[:check_amount_words\]/, :on => :create, :message => "check_amount_words is invalid"
  validates_format_of :rtf, :with => /@check_details\[:customer_name\]/, :on => :create, :message => "customer_name is invalid"
  validates_format_of :rtf, :with => /@check_details\[:customer_address_street\]/, :on => :create, :message => "customer_address_street is invalid"
  validates_format_of :rtf, :with => /@check_details\[:customer_address_street_2\]/, :on => :create, :message => "customer_address_street_2 is invalid"
  validates_format_of :rtf, :with => /@check_details\[:customer_address_city\]/, :on => :create, :message => "customer_address_city is invalid"

  before_destroy do
    throw :abort unless can_destroy?
  end
  after_save :init_default!

  def can_destroy?
    errors.add(:base, "You can't delete the default template.") if as_default?
    errors[:base].empty?
  end

  def init_default!
    if as_default
      CheckTemplate.where.not(id: id).update_all(as_default: false)
    else
      CheckTemplate.first.update(as_default: true)
    end
  end

  def rtf=(file_field)
    if !file_field.kind_of?(String)
      write_attribute(:rtf, file_field.read)
    end
  end

  def self.default
    CheckTemplate.find_by(as_default: true)
  end

end

