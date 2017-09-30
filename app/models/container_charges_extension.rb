module ContainerChargesExtension
  # computes the total amount per company.
  def amount(company_id)
    charges(company_id).inject(0){|sum, cc| sum + cc.amount}
  end

  def charges(company_id)
    scope.where("container_charges.company_id = ?", company_id)
  end

  # receivable_container_charges.chargable(31, 'ReceivableCharge')
  def chargable(id, type)
    scope.where("container_charges.chargable_id = ? AND container_charges.chargable_type = ?", id, type)
  end

  def total_amount
    load_target.inject(0){|sum, p| sum + p.amount}
  end

  # Kinda like new, but for more container_charges
  # ["["-710653852663", {"details"=>"", "amount"=>"", "company_id"=>"", "key"=>"-710653852663", "delete_it"=>"", "chargable_id"=>"23", "chargable_type" => "PayableCharge" }]", {"details"=>"", "amount"=>"", "company_id"=>"", "key"=>"-710653852663", "delete_it"=>"", "chargable_id"=>"23",  "chargable_type" => "PayableCharge"}]
  def new_collection(params)
    params.each do |key, new_attributes|
      next if new_attributes["delete_it"] == "1"
      build(new_attributes)
    end if params
  end

  #updates the collection, but doesn't save it
  def update_collection(params)
    if params.present? # very important!!!
      # old objects
      # when editing a container without pay or rec charges, there are no existing
      # charges to be updated. 'if existing' makes sure the update won't fail
      existing_charges = load_target.reject(&:new_record?)
      existing_charges.each do |cc|
        next if !cc.can_be_modified?
        new_attributes = params[cc.id.to_s]
        if !new_attributes || new_attributes[:delete_it] == "1"
          cc.mark_for_destruction #autosave: true => mark to delete after parent save
        else
          cc.attributes = new_attributes
        end
      end if existing_charges
      #new objects
      params.to_h.find_all{|key, value| key.to_i < 0}.each do |key, new_attributes|
        next if new_attributes[:delete_it] == "1"
        build(new_attributes)
      end
    end
  end

  def save_changed
    load_target.each do |cc|
      cc.save if cc.changed?
    end
  end

  def set_invoice_if_applicable
    load_target.group_by(&:company_id).each do |company_id, charges|
      invoiced = charges.detect{|c| c.line_item_id }
      if invoiced
        charges.each do |cc|
          cc.update_attribute(:line_item_id, invoiced.line_item_id) unless cc.line_item_id == invoiced.line_item_id
        end
      end
    end
  end

end
