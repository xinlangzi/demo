class ReceivableLineItem < ContainerLineItem
  validates_each :amount do |record, attr, value|
    #Amount has to be equal with the sum of all container charges for that company
    container_charges_amount = record.container.receivable_container_charges.amount(record.invoice.company_id)
    if container_charges_amount != record.amount
      record.errors.add :amount, "must match receivable charges in the container of $#{container_charges_amount}"
    end
  end

  after_create :mark_edi_complete
  after_destroy :mark_edi_incomplete

  def accounts
    return :receivable
  end

  def update_receivable_line_item(for_company)
     amount = container.charges(accounts, for_company.id).inject(0){|sum, c| sum += c.amount}
     invoice.update_amount
  end

  def mark_edi_complete
    container = self.container
    container.update_column(:edi_complete, true) unless container.customer.edi_provider.try(:send_invoice_by_edi?)
  end

  def mark_edi_incomplete
    container = self.container
    if !container.customer.edi_provider.try(:send_invoice_by_edi?) && ReceivableLineItem.where(container_id: container.id).count == 0
      container.update_column(:edi_complete, false)
    end
  end
end
