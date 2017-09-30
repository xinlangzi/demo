class FinancialsController < ApplicationController

  def index

  end

  def payables

  end

  def receivables

  end

  def performance_dashboard
    @filter = AccountingContainerFilter.build_from_performance_dashboard(params)
    @invoice_filter = InvoiceFilter.build_from_performance_dashboard(params)
    @filter.valid?

    csearch = @filter.search_by_delivered_date.freeze
    isearch = @invoice_filter.search_by_invoice_date.freeze

    @containers = Container.search(csearch).result

    @container_revenue = ReceivableContainerCharge.total.search(@filter.search_charges_by_delivered_date).result.first.total
    @container_cost = PayableContainerCharge.total.search(@filter.search_charges_by_delivered_date).result.first.total
    @tp_revenue = Accounting::ReceivableInvoice.total.search(isearch).result.first.total
    @tp_cost = Accounting::PayableInvoice.total.search(isearch).result.first.total

    @receivable_container_charges_sql = Sql.build(ReceivableContainerCharge.performance.search(@filter.search_charges_by_delivered_date).result.to_sql)
    @payable_container_charges_sql = Sql.build(PayableContainerCharge.performance.search(@filter.search_charges_by_delivered_date).result.to_sql)
    @tp_receivable_invoices_sql = Sql.build(Accounting::ReceivableInvoice.performance.search(isearch).result.to_sql)
    @tp_payable_invoices_sql = Sql.build(Accounting::PayableInvoice.performance.search(isearch).result.to_sql)

    @tp_receivable_invoices_per_company = Accounting::ReceivableInvoice.total_by_company.search(isearch).result.includes(:company).all
    @tp_payable_invoices_per_company = Accounting::PayableInvoice.total_by_company.search(isearch).result.includes(:company).all
    @receivable_invoices = ReceivableInvoice.totals.search(isearch).result.includes(:company).all
    @payable_invoices = PayableInvoice.totals.search(isearch).result.includes(:company).all

    @outstanding_receivable_invoices = ReceivableInvoice.outstanding.totals.search(isearch).result
    @outstanding_payable_invoices = PayableInvoice.outstanding.totals.search(isearch).result

    @uninvoiced_receivable_containers = Container.filter(@filter).uninvoiced_cached(:receivable).count("DISTINCT containers.id")
    @uninvoiced_payable_containers = Container.filter(@filter).uninvoiced_cached(:payable).count("DISTINCT containers.id")
    @uninvoiced_containers = @uninvoiced_receivable_containers + @uninvoiced_payable_containers
  end

  def health_indicator
    outstanding_receivables = ReceivableInvoice.outstanding.health_indicator
    @outstanding_receivables_sql = Sql.build(outstanding_receivables.to_sql)
    @total_outstanding_receivables = outstanding_receivables.to_a.sum(&:final_balance)

    outstanding_payables = PayableInvoice.outstanding.health_indicator
    @outstanding_payables_sql = Sql.build(outstanding_payables.to_sql)
    @total_outstanding_payables = outstanding_payables.to_a.sum(&:final_balance)

    tp_outstanding_receivables = Accounting::ReceivableInvoice.outstanding.health_indicator
    @tp_outstanding_receivables_sql = Sql.build(tp_outstanding_receivables.to_sql)
    @total_tp_outstanding_receivables = tp_outstanding_receivables.to_a.sum(&:final_balance)

    tp_outstanding_payables = Accounting::PayableInvoice.outstanding.health_indicator
    @tp_outstanding_payables_sql = Sql.build(tp_outstanding_payables.to_sql)
    @total_tp_outstanding_payables = tp_outstanding_payables.to_a.sum(&:final_balance)

    uninvoiced_container_ids = Container.uninvoiced_cached(:receivable).select(:id).distinct
    uninvoiced_receivables = ReceivableContainerCharge.health_indicator.joins(:container).where("containers.id IN (?) AND line_item_id IS NULL", uninvoiced_container_ids)
    @uninvoiced_receivables_sql = Sql.build(uninvoiced_receivables.to_sql)
    @total_uninvoiced_receivables = uninvoiced_receivables.sum(:amount)

    uninvoiced_container_ids = Container.uninvoiced_cached(:payable).select(:id).distinct
    uninvoiced_payables = PayableContainerCharge.health_indicator.joins(:container).where("containers.id IN (?) AND line_item_id IS NULL", uninvoiced_container_ids)
    @uninvoiced_payables_sql = Sql.build(uninvoiced_payables.to_sql)
    @total_uninvoiced_payables = uninvoiced_payables.sum(:amount)

    @outstanding_difference = @total_outstanding_receivables - @total_outstanding_payables
    @tp_outstanding_difference = @total_tp_outstanding_receivables - @total_tp_outstanding_payables
    @uninvoiced_difference = @total_uninvoiced_receivables - @total_uninvoiced_payables
  end

  # def balance_sheet
  #   @filter = BalanceSheetFilter.new(params[:filter])
  #   @filter.default_date_range!
  #   @receivable_charges = @filter.receivable_container_charges
  #   @payable_charges = @filter.payable_container_charges
  #   @tp_receivable_line_items = @filter.tp_receivable_line_items
  #   @tp_payable_line_items = @filter.tp_payable_line_items

  #   @receivable_container_charges_sql = Sql.build(@filter.receivable_container_charges.to_sql)
  #   @payable_container_charges_sql = Sql.build(@filter.payable_container_charges.to_sql)
  #   @tp_receivable_line_items_sql = Sql.build(@filter.tp_receivable_line_items.to_sql)
  #   @tp_payable_line_items_sql = Sql.build(@filter.tp_payable_line_items.to_sql)
  # end

  # def profit_loss
  #   @filter = ProfitLossFilter.new(params[:filter])
  #   @filter.default_date_range!
  #   @receivable_charges = @filter.receivable_container_charges
  #   @payable_charges = @filter.payable_container_charges
  #   @tp_receivable_line_items = @filter.tp_receivable_line_items
  #   @tp_payable_line_items = @filter.tp_payable_line_items

  #   @receivable_container_charges_sql = Sql.build(@filter.receivable_container_charges.to_sql)
  #   @payable_container_charges_sql = Sql.build(@filter.payable_container_charges.to_sql)
  #   @tp_receivable_line_items_sql = Sql.build(@filter.tp_receivable_line_items.to_sql)
  #   @tp_payable_line_items_sql = Sql.build(@filter.tp_payable_line_items.to_sql)
  # end
end
