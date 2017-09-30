module InvoiceSearch

  PERIODS = [
    "0to15", "15to30", "30to45", "45to60", "60to90", "90to120", "120to"
  ].freeze

  AGINGS = PERIODS.inject({}){|map, period|
    l, r = period.split('to').map(&:to_i)
    # l = -1 if l == 0
    map[period] = r.nil? ? ->(o){ o.until(l.days.ago) } : ->(o){ o.between(r.days.ago, l.days.ago) }
    map
  }.freeze

  AGING_DETAILS = PERIODS.inject({}){|map, period|
    l, r = period.split('to').map(&:to_i)
    map[period] = r.nil? ? "Invoices aging over #{l} days" : "Invoices aging #{l} to #{r} days"
    map
  }.freeze

  REFERRED_PAYMENT_DATES = {
    receivable: [ 'Issue Date', 'Received Date', 'Cleared Date'],
    payable: ['Issue Date', 'Cleared Date']
  }.freeze

  REFERRED_PAYMENT_DATES_COLUMN_NAMES = {
    'Issue Date'    => 'issue_date',
    'Received Date' => 'date_received',
    'Cleared Date'  => 'cleared_date'
  }.freeze

  def self.included(base)
    base.class_eval do
      scope :for_user,  ->(user){
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
      scope :outstanding, ->{ where("invoices.balance != ?", 0) }
      scope :non_outstanding, ->{ where("invoices.balance = ?", 0) }
      scope :between, ->(from, to){ where("invoices.issue_date >= ? AND invoices.issue_date < ?", from.to_date + 1, to.to_date + 1) }
      scope :until, ->(to){ where("invoices.issue_date <= ?", to.to_date) }
      scope :health_indicator, ->{
        select("invoices.*, companies.name AS company_name, SUM(credits.amount) AS credits, SUM(adjustments.amount) AS adjustments, invoices.balance - IFNULL(SUM(credits.amount), 0) - IFNULL(SUM(adjustments.amount), 0) AS final_balance").
        joins(:company).
        joins("LEFT OUTER JOIN credits ON credits.invoice_id = invoices.id").
        joins("LEFT OUTER JOIN adjustments ON adjustments.invoice_id = invoices.id").
        order("invoices.issue_date ASC").
        group("invoices.id").
        having("final_balance > 0")
      }
      scope :period_summary, ->(options){
        options||= {}
        outstanding = options[:outstanding_true].to_boolean
        referred_date = options[:referred_payment_date]|| 'Issue Date'
        date_column = REFERRED_PAYMENT_DATES_COLUMN_NAMES[referred_date]
        date = outstanding ? (options[:as_of] || Date.today) : Date.today.end_of_year
        relation = select("
          invoices.*,
          IFNULL((SELECT SUM(credits.amount) FROM credits
                  WHERE credits.issue_date <= '#{date}' AND credits.invoice_id = invoices.id), 0) AS credit,
          IFNULL((SELECT SUM(credits.amount) FROM credits
                  INNER JOIN payments ON payments.id = credits.payment_id AND payments.#{date_column} <= '#{date}'
                  WHERE credits.issue_date <= '#{date}' AND credits.invoice_id = invoices.id), 0) AS credited,
          IFNULL((SELECT SUM(adjustments.amount) FROM adjustments
                  WHERE adjustments.invoice_id = invoices.id), 0) AS adjustment,
          IFNULL((SELECT SUM(adjustments.amount) FROM adjustments
                  INNER JOIN payments ON payments.id = adjustments.payment_id AND payments.#{date_column} <= '#{date}'
                  WHERE adjustments.invoice_id = invoices.id), 0) AS adjusted,
          IFNULL((SELECT SUM(line_item_payments.amount) FROM line_items
                  INNER JOIN line_item_payments ON line_item_payments.line_item_id = line_items.id
                  INNER JOIN payments ON payments.id = line_item_payments.payment_id AND payments.#{date_column} <= '#{date}'
                  WHERE line_items.invoice_id = invoices.id), 0) AS paid"
          ).where("invoices.issue_date <= ?", date)
        relation = relation.having("amount - paid + (credit - credited) + (adjustment - adjusted) > 0") if outstanding
        relation
      }
      scope :container_no_cont, ->(value){
        joins("INNER JOIN line_items ON line_items.invoice_id = invoices.id").
        joins("INNER JOIN containers ON line_items.container_id = containers.id").
        where("containers.container_no LIKE ?", "%#{value}%")
      }

      scope :outstanding_true, ->{}
      scope :as_of, ->(date){}
      scope :referred_payment_date, ->(refer){}

      ransacker :invoice_no, formatter: proc{ |v| v.split(/\,/).map(&:strip) } do |parent|
        parent.table[:number]
      end

      def self.ransackable_scopes(auth=nil)
        %w[outstanding_true as_of referred_payment_date container_no_cont]
      end

      def self.group_by_period(options={}, period=nil)
        outstanding = options[:outstanding_true].to_boolean
        {}.tap do |h|
          AGINGS.each do |name, proc|
            next if period&&period!=name
            relation = period_summary(options)
            relation = proc.call(relation)
            relation = outstanding ? relation.order("issue_date ASC") : relation.order("issue_date DESC")
            search   = relation.search(options)
            sql =<<EOF
SELECT
 COUNT(invoices.id) AS count,
 IFNULL(SUM(invoices.amount), 0) AS amount,
 IFNULL(SUM(invoices.credit), 0) AS credit,
 IFNULL(SUM(invoices.adjustment), 0) AS adjustment,
 IFNULL(SUM(invoices.paid) + SUM(invoices.credited) + SUM(invoices.adjusted), 0) AS paid,
 IFNULL(SUM(invoices.amount) - SUM(invoices.paid) + (SUM(invoices.credit) - SUM(invoices.credited)) + (SUM(invoices.adjustment) - SUM(invoices.adjusted)), 0) AS balance
FROM (#{search.result.to_sql}) invoices
EOF
            totals = find_by_sql(sql)
            h[name]= {
              invoices: search.result.includes([ :company, { line_items: :container } ]),
              size: totals.first.count,
              total_amount: totals.first.amount,
              total_credit: totals.first.credit,
              total_adjustment: totals.first.adjustment,
              total_paid: totals.first.paid,
              total_balance: totals.first.balance
            }
          end
        end
      end
    end
  end
end
