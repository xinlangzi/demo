class Accounting::TpCompany < Company

	validates :name, uniqueness: {scope: [:type], case_sensitive: false }
	validates :print_name, :address_street, :address_city, :address_state_id, :zip_code, presence: true

	has_many :invoices, :class_name => 'Accounting::Invoice', :foreign_key => :company_id

	scope :inactive, ->{ where('companies.inactived_at IS NOT NULL AND companies.deleted_at IS NULL').order('name ASC') }
	scope :deleted, ->{ where('companies.deleted_at IS NOT NULL').order('name ASC') }
	scope :active, ->{ where('companies.inactived_at IS NULL AND companies.deleted_at IS NULL').order('name ASC') }
  scope :outstanding, ->(accounts){ where(id: Accounting::Invoice.outstanding_companies_id(accounts)) }
  scope :group_options, ->{ where(for_container: true).order('name ASC') }
  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin'
      all
    when 'Admin'
      if user.has_role?(:accounting)
        all
      else
        where("IFNULL(acct_only, false) = ?", false)
      end
    else raise "Authentication / Access error for #{user.class}"
    end
  }

	validate do
    errors.add(:base, ABSTRACT_CLASS_INST_ERROR%"Accounting::TpCompany")  unless self.class != Accounting::TpCompany
  end

  def self.mark
    to_s.demodulize.underscore
  end

  def self.titleize
    to_s.demodulize.titleize
  end

	def inactived?
		inactived_at?
	end

	def can_delete?
    errors.add(:base, "can not be deleted before all its invoices have not been paid in full.") if invoices.sum('balance') != 0
    errors[:base].empty?
  end

  def address
    [self.address_street, self.address_street_2, self.address_city, "#{self.state} #{self.zip_code}"].compact.join(', ')
  end
end