class Payment < ApplicationRecord
  include PaymentCreditAssociation
  has_many_credits

  belongs_to :admin
  belongs_to :company

  validates :admin_id, :company_id, presence: true
  validates :payment_method_id, :issue_date, presence: true

  scope :uncleared, ->{ where(cleared_date: nil) }
  scope :payables, ->{ where('payments.type like ?', '%Payable%') }
  scope :receivables, ->{ where('payments.type like ?', '%Receivable%') }
  scope :reconciled, ->{ where.not(reconciliation_id: nil) }
  scope :unreconciled, ->{ where(reconciliation_id: nil).where.not(cleared_date: nil).includes(:company, :payment_method) }
  scope :non_tp, ->{ where('payments.type not like ?', '%Accounting%') }
  scope :tp, ->{ where('payments.type like ?', '%Accounting%') }
  scope :overpaid, ->{ where('payments.balance > ?', 0) }
  scope :ascend_by_company_name_and_issue_date, ->{ includes(:company).order('companies.name asc, issue_date asc') }
  scope :for_user, ->(user){
    case user.class.to_s
    when 'SuperAdmin'
      all
    when 'Admin'
      if user.has_role?(:accounting)
        all
      else
        where.not(company_id: Company.where(acct_only: true).select(:id))
      end
    when 'CustomersEmployee'
      where(company_id: user.customer.id)
    when 'Trucker'
      where(company_id: user.id)
    else raise "Authentication / Access error for #{user.class}"
    end
  }

  scope :category, ->(value){
    type, id = value.split('-')
    joins("LEFT OUTER JOIN line_item_payments ON line_item_payments.payment_id = payments.id").
    joins("LEFT OUTER JOIN line_items ON line_items.id = line_item_payments.line_item_id").
    joins("LEFT OUTER JOIN container_charges ON container_charges.line_item_id = line_items.id").
    where(
      "(line_items.type LIKE ? AND line_items.category_id = ?) OR (container_charges.chargable_type = ? AND container_charges.chargable_id = ?)",
      "Accounting%", id, type, id
    )
  }

  ransacker :payment_no, formatter: proc{|v| v.split(/\,/).map(&:strip) } do |parent|
    parent.table[:number]
  end

  before_validation :set_admin, on: :create

  def self.ransackable_scopes(auth=nil)
    [:category]
  end

  def is_check_payment?
    payment_method == PaymentMethod.check
  end

  def self.onfile1099_to_csv(payments)
    CSV.generate do |csv|
      csv << [
        "Company",
        "Amount",
        "Print Name",
        "SSN",
        "Street",
        "City",
        "State",
        "Zip Code",
        "Type"
      ]
      payments.group_by(&:company).each do |company, payments|
        next unless company.onfile1099
        is_trucker = company.is_a?(Trucker)
        csv << [
          company.name,
          payments.map(&:amount).sum,
          company.print_name,
          company.ssn,
          (is_trucker ? company.billing_street : company.address_street),
          (is_trucker ? company.billing_city : company.address_city),
          (is_trucker ? company.billing_state.try(:abbrev) : company.address_state.try(:abbrev)),
          (is_trucker ? company.billing_zip_code : company.zip_code),
          (is_trucker ? 'Trucker' : 'Third Party Vendor')
        ]
      end
    end

  end

  private

    def set_admin
      self.admin||= User.authenticated_user
    end
end
