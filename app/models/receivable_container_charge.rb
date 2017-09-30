class ReceivableContainerCharge < ContainerCharge

  def charges
    case chargable_type
    when "ReceivableCharge"
      self.class.charges
    when "Accounting::Category"
      Accounting::Category.revenue.for_container
    else
      []
    end
  end

  def self.charges
    ReceivableCharge.all
  end

  # returns an array of type of companies select's optgroup option
  def companies
    case chargable_type
    when "ReceivableCharge"
      [Customer, Ssline] # insert new company type if new optgroup option is needed
    when "Accounting::Category"
      [Accounting::TpCustomer]
    else
      []
    end
  end
end
