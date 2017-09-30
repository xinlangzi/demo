class Report::Reconciliation < ApplicationRecord
  mount_uploader :file, AttachmentUploader
  attr_accessor :pids, :search_params
  belongs_to :user
  has_many :payments
  has_many :line_item_payments, through: :payments
  has_many :line_items, through: :line_item_payments
  has_many :container_charges, through: :line_items
  has_many :invoices, through: :line_items
  validates :name, presence: true
  validates :pids, presence: true, unless: :backend?

  after_save :reconcile, unless: :backend?
  before_destroy :unreconcile

  default_scope { order("id DESC") }

  def file_exists?
    file.file.exists? rescue false
  end

  def search_params
    @search_params||= { cleared_date_gteq: cleared_from, cleared_date_lteq: cleared_to }
  end

  def filter_payments
    (backend? || new_record?&&search_params) ? Payment.reconciled.search(search_params).result : self.payments
  end

  def reconcile
    prev_pids = filter_payments.collect(&:id)
    pids_to_reconcile = (pids - prev_pids)
    pids_to_unreconcile = (prev_pids - pids)
    Payment.where(id: pids_to_unreconcile).update_all(reconciliation_id: nil)
    Payment.where(id: pids_to_reconcile).update_all(reconciliation_id: id)
  end

  def charge_paid_ratio
    unless @container_paid_ratio
      container_paid = { receivable: {}, payable: {} }
      container_paid_ratio = { receivable: {}, payable: {} }
      [:receivable, :payable].each do |type|
        pids = filter_payments.send(type.to_s.pluralize.to_sym).non_tp.map(&:id)
        LineItemPayment.select("DISTINCT(line_item_payments.id), line_item_payments.amount AS paid, line_items.amount AS total, line_items.container_id AS cid, line_items.id AS liid").joins(:line_item).where(payment_id: pids).each do |row|
          cid = row.cid
          liid = row.liid
          container_paid[type][cid]||= { liids: [], total: BigDecimal('0.00'), paid: BigDecimal('0.00') }
          unless container_paid[type][cid][:liids].include?(liid)
            container_paid[type][cid][:liids] << liid
            container_paid[type][cid][:total]+= BigDecimal(row.total.to_s)
          end
          container_paid[type][cid][:paid]+= BigDecimal(row.paid.to_s)
        end
        container_paid[type].each{|cid, values| container_paid_ratio[type][cid] = values[:paid]/values[:total]}
      end
    end
    @container_paid_ratio ||= container_paid_ratio
  end

  # def by_categories
  #   summary = {}
  #   container_paid_ratio = charge_paid_ratio
  #   [:receivable, :payable].each do |type|
  #     line_items = {}
  #     pids = filter_payments.send(type.to_s.pluralize.to_sym).tp.map(&:id)
  #     LineItem.select("DISTINCT(line_items.id), line_items.category_id AS cid, SUM(line_items.amount) AS total").group(:category_id).joins(:line_item_payments).where("line_item_payments.payment_id in (?)", pids).each do |row|
  #       line_items[row.cid] = row.total
  #     end
  #     container_charges = {}
  #     pids = filter_payments.send(type.to_s.pluralize.to_sym).non_tp.map(&:id)
  #     ContainerCharge.select("DISTINCT(container_charges.id), container_charges.chargable_id, container_charges.amount, container_charges.container_id").joins(:line_item => :line_item_payments).where("line_item_payments.payment_id in (?)", pids).group_by(&:chargable_id).each do |cid, ccs|
  #       container_charges[cid] = ccs.inject(BigDecimal(0)){|sum, cc| sum + BigDecimal(cc.amount.to_s) * container_paid_ratio[type][cc.container_id] }
  #     end
  #     summary[type] = { tp: line_items, non_tp: container_charges}
  #   end
  #   pids = filter_payments.payables.non_tp.map(&:id)
  #   summary[:adjustments] = Adjustment.where(payment_id: pids).map(&:amount).sum
  #   summary
  # end

  def by_companies
    ret = { receivable: [], payable: []}
    filter_payments.includes([:company, :payment_method]).each do |payment|
      sym = payment.type =~/receivable/i ? :receivable : :payable
      ret[sym] << payment
      ret[sym].uniq!
    end
    ret
  end

  def overpay_by_companies
    filter_payments.receivables.overpaid.group_by(&:company)
  end

  def classify_by_container_charge
    ratios = self.charge_paid_ratio
    ret = { receivable: {}, payable: {} }
    pids = filter_payments.non_tp.map(&:id)

    ContainerCharge.select(
        "DISTINCT(container_charges.id),
        container_charges.amount AS amount,
        container_charges.chargable_id AS chargable_id,
        container_charges.chargable_type AS chargable_type,
        companies.name AS company_name,
        companies.id AS company_id,
        invoices.id AS invoice_id,
        invoices.number AS invoice_number,
        invoices.type AS invoice_type,
        line_items.type AS line_item_type,
        container_charges.container_id AS container_id"
      ).joins(
        [ {line_item: [:line_item_payments, { invoice: :company}]} ]
      ).where(
        "line_item_payments.payment_id in (?)", pids
      ).includes(
        [:chargable]
      ).each do |row|
        sym = row.line_item_type =~/receivable/i ? :receivable : :payable
        charge_info = "#{row.chargable.name}-#{row.chargable_id}"
        company_info = "#{row.company_name}-#{row.company_id}"
        invoice_number = row.invoice_number
        invoice_id = row.invoice_id
        invoice_type = row.invoice_type
        container_id = row.container_id
        ret[sym][charge_info]||={}
        ret[sym][charge_info][company_info]||={}
        ret[sym][charge_info][company_info][invoice_id]||={}
        ret[sym][charge_info][company_info][invoice_id][:amount]||= BigDecimal('0.00')
        ret[sym][charge_info][company_info][invoice_id][:number] = invoice_number
        ret[sym][charge_info][company_info][invoice_id][:type] = invoice_type
        ret[sym][charge_info][company_info][invoice_id][:amount]+= (BigDecimal(row.amount.to_s) * ratios[sym][container_id] || 1.0)
    end
    ret
  end

  def classify_by_third_party_category
    ret = {receivable: { ids: []}, payable: {ids: []}}
    pids = filter_payments.tp.map(&:id)
    LineItem.joins(:line_item_payments
    ).where("line_item_payments.payment_id in (?)", pids
    ).includes([:category, {invoice: :company}]).each do |line_item|
      sym = line_item.type =~/receivable/i ? :receivable : :payable
      category_info = "#{line_item.category.name}-#{line_item.category.id}"
      company_info = "#{line_item.invoice.company.name}-#{line_item.invoice.company.id}"
      invoice_number = line_item.invoice.number
      invoice_id = line_item.invoice.id
      invoice_type = line_item.invoice.type
      ret[sym][category_info]||={}
      ret[sym][category_info][company_info]||={}
      ret[sym][category_info][company_info][invoice_id]||={}
      ret[sym][category_info][company_info][invoice_id][:amount]||= BigDecimal('0.00')
      ret[sym][category_info][company_info][invoice_id][:number] = invoice_number
      ret[sym][category_info][company_info][invoice_id][:type] = invoice_type
      ret[sym][category_info][company_info][invoice_id][:amount]+= BigDecimal(line_item.amount.to_s)
      ret[sym][:ids] << line_item.category_id
      ret[sym][:ids].uniq!
    end
    ret
  end

  def classify_by_credit_category
    ret = { receivable: {}, payable: {} }
    pids = filter_payments.map(&:id)
    Credit.where(payment_id: pids).includes(:catalogable, { invoice: :company }).each do |credit|
      sym = credit.type =~/customer/i ? :receivable : :payable
      category_info = "#{credit.catalogable.name}-#{credit.catalogable.id}"
      company_info = "#{credit.invoice.company.name}-#{credit.invoice.company.id}"
      invoice_number = credit.invoice.number
      invoice_id = credit.invoice.id
      invoice_type = credit.invoice.type
      ret[sym][category_info]||={}
      ret[sym][category_info][company_info]||={}
      ret[sym][category_info][company_info][invoice_id]||={}
      ret[sym][category_info][company_info][invoice_id][:amount]||= BigDecimal('0.00')
      ret[sym][category_info][company_info][invoice_id][:number] = invoice_number
      ret[sym][category_info][company_info][invoice_id][:type] = invoice_type
      ret[sym][category_info][company_info][invoice_id][:amount]+= BigDecimal(credit.amount.to_s)
    end
    ret
  end

  def classify_by_adjustment_category
    ret = {}
    pids = filter_payments.payables.non_tp.map(&:id)
    Adjustment.where(payment_id: pids).includes(:category, {invoice: :company} ).each do |adjustment|
      category_info = "#{adjustment.category.name}-#{adjustment.category.id}"
      company_info = "#{adjustment.invoice.company.name}-#{adjustment.invoice.company.id}"
      invoice_number = adjustment.invoice.number
      invoice_id = adjustment.invoice.id
      invoice_type = adjustment.invoice.type
      ret[category_info]||={}
      ret[category_info][company_info]||={}
      ret[category_info][company_info][invoice_id]||={}
      ret[category_info][company_info][invoice_id][:amount]||= BigDecimal('0.00')
      ret[category_info][company_info][invoice_id][:number] = invoice_number
      ret[category_info][company_info][invoice_id][:type] = invoice_type
      ret[category_info][company_info][invoice_id][:amount]+= BigDecimal(adjustment.amount.to_s)
    end
    ret
  end

  def csv_by_category
    extract_name = Proc.new{|name| name =~/\A(.*)-\d*\Z/; $1 }
    CSV.generate do |csv|
      csv << ['Category', 'Amount']
      classify_for_containers = classify_by_container_charge
      classify_for_third_parties = classify_by_third_party_category
      classify_for_credits  = classify_by_credit_category
      classify_for_adjustments = classify_by_adjustment_category
      [:receivable, :payable].each do |sym|
        classify_for_containers[sym].each do |category_info, nested_hash|
          csv << [extract_name.call(category_info), nested_hash.values_for(:amount).sum.round(2)] rescue nil
        end
        classify_for_third_parties[sym].each do |category_info, nested_hash|
          csv << [extract_name.call(category_info), nested_hash.values_for(:amount).sum.round(2)] rescue nil
        end
        classify_for_credits[sym].each do |category_info, nested_hash|
          csv << [extract_name.call(category_info), nested_hash.values_for(:amount).sum.round(2)] rescue nil
        end
        csv << ['', '']
      end
      classify_for_adjustments.each do |category_info, nested_hash|
        csv << [extract_name.call(category_info), nested_hash.values_for(:amount).sum.round(2)] rescue nil
      end
    end

  end

  def unreconcile
    Payment.where(reconciliation_id: id).update_all(reconciliation_id: nil)
  end

  def payable_amount
    filter_payments.payables.map(&:amount).map(&:to_f).sum
  end

  def receivable_amount
    filter_payments.receivables.map(&:amount).map(&:to_f).sum
  end

end
