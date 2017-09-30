require 'csv'
require 'bigdecimal'
class Invoice < ApplicationRecord
  include InvoiceSearch
  include InvoiceCreditAssociation
  include InvoiceAdjustmentAssociation
  has_many_credits
  has_many_adjustments

  has_paper_trail only: [:number, :issue_date, :comments, :due_date, :date_sent, :date_received, :last_notification_date, :balance, :amount]

  belongs_to :admin
  belongs_to :company

  validates :admin_id, :company_id, presence: true

  before_validation :set_admin, on: :create

  #ATTN: Don't put this here: has_many :line_items, dependent: :destroy

  def outstanding?
    balance != 0.0
  end

  def payments
    @payments||= Payment.joins("INNER JOIN line_item_payments ON line_item_payments.payment_id = payments.id")
                        .where('line_item_payments.line_item_id IN (?)', line_items.map(&:id)).distinct.to_a
  end

  def to_pdf(html)
    Wisepdf::Writer.new.to_pdf(html, page_size: "letter", margin: { top: 5, bottom: 5, left: 5, right: 5 })
  end

  def self.outstanding_csv(invoices)
    total_amount, total_balance, total_credit, total_adjustment, total_paid = [0]*5
    CSV.generate do |csv|
      csv << [
        'Number',
        'Reference No.',
        'Company',
        'Invoice Date',
        'Amount',
        'Credit',
        'Adjustment',
        'Paid',
        'Balance'
      ]
      invoices.each do |invoice|
        amount    = invoice.amount
        credit    = invoice.credit
        adjustment = invoice.adjustment
        paid      = invoice.paid - invoice.credited + invoice.adjusted
        balance   = invoice.amount - invoice.paid + (invoice.credit - invoice.credited) + (invoice.adjustment - invoice.adjusted)
        total_amount+= amount
        total_credit+= credit
        total_adjustment+= adjustment
        total_paid+= paid
        total_balance+= balance
        csv << [
          invoice.number,
          (invoice.containers.map(&:reference_no).uniq.join(';') rescue 'N/A'),
          invoice.company.name,
          invoice.issue_date.us_date,
          number_to_currency(amount),
          number_to_currency(credit),
          number_to_currency(adjustment),
          number_to_currency(paid),
          number_to_currency(balance)
        ]
      end
      csv << ['', '', '', '', 'Total Amount', 'Total Credit', 'Total Adjustment', 'Total Paid', 'Total Balance']
      csv << ['', '', '', '', number_to_currency(total_amount), number_to_currency(total_credit), number_to_currency(total_adjustment), number_to_currency(total_paid), number_to_currency(total_balance)]
    end
  end

  private

    def set_admin
      self.admin||= User.authenticated_user
    end
end
