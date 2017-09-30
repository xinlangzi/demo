class InvoiceFilter < Filter

  def sql_conditions(scoped)
    scoped = scoped.where("invoices.company_id = ?", the_company_id) unless the_company_id.blank?
    scoped = scoped.where("invoices.issue_date >= ?", from.to_datetime) unless from.blank?
    scoped = scoped.where("invoices.issue_date < ?", to.to_datetime + 1) unless to.blank?
    scoped
  end

  def the_company_id
    company_id || tp_company_id
  end

  def third_party?
    company_id.blank?&&tp_company_id.present?
  end

  def search_by_invoice_date
    { issue_date_gteq: self.from.to_datetime, issue_date_lt: (self.to.to_datetime + 1 rescue nil) }
  end

  def search_by_delivered_date
    { line_items_container_delivered_date_gteq: self.from.to_datetime, line_items_container_delivered_date_lt: (self.to.to_datetime + 1 rescue nil) }
  end

end
