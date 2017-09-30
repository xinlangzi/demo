class AccountingContainerFilter < Filter

  validates_each :from, allow_blank: true do |record, attribute, value|
    if record.from.present? && record.to.present? && record.from > record.to
      record.errors.add attribute, "cannot be sooner than the date until."
    end
  end

  def sql_conditions(scoped)
    scoped = scoped.where("container_charges.company_id = ?", the_company_id) unless the_company_id.blank?
    scoped = scoped.where("delivered_date >= ?", from.to_datetime) unless from.blank?
    scoped = scoped.where("delivered_date < ?", to.to_datetime + 1) unless to.blank?
    scoped = scoped.where("container_no LIKE ?", "%#{container_no}%") unless container_no.blank?
    scoped
  end

  def the_company_id
    company_id || tp_company_id
  end

  def third_party?
    company_id.blank?&&tp_company_id.present?
  end

  def search_by_delivered_date
    { delivered_date_gteq: self.from.to_datetime, delivered_date_lt: (self.to.to_datetime + 1 rescue nil) }
  end

  def search_by_invoice_date
    { line_items_invoice_issue_date_gteq: self.from.to_datetime, line_items_invoice_issue_date_lt: (self.to.to_datetime + 1 rescue nil) }
  end

  def search_charges_by_delivered_date
    { container_delivered_date_gteq: self.from.to_datetime, container_delivered_date_lt: (self.to.to_datetime + 1 rescue nil) }
  end

end
