class PayableLineItem < ContainerLineItem
  validates_each :amount do |record, attr, value|
    #Amount has to be equal with the sum of all container charges for that company
    container_charges_amount = record.container.payable_container_charges.amount(record.invoice.company_id)
    if container_charges_amount != record.amount
      record.errors.add :amount, "must match payable charges in the container of $#{container_charges_amount}"
    end
  end

end
