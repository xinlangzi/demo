class CustomerCredit < Credit

  def self.catalog_options(user)
    grouped_options = []
    grouped_options << ["Accounting Categories", Accounting::Category.parent_options(user, "revenue", nil, false).map{|c| [c[0], "#{Accounting::Category}-#{c[1]}"] }]
    grouped_options << ["Container Charge Categories", ReceivableCharge.all.map{|c| [c.name, "Charge-#{c.id}"] }]
    grouped_options
  end

end