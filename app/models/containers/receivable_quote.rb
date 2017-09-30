class ReceivableQuote < Tableless
  attr_accessor :container, :target_id, :charge_ids, :save_mode

  validate do
    errors.add(:base, "Customer is required.") unless customer
    errors.add(:base, "Check consignee or shipper with valid zip code.") unless destination.try(:zip_code)
    errors.add(:base, "Check terminal with mapped rail road.") unless rail_road
  end

  def target
    @target||= case target_id
    when /sq:(\d+)/
      SpotQuote.find($1)
    when /c:(\d+)/
      Container.find($1)
    end
  end

  def companies
    @companies||= container.operations.map(&:company).compact
  end

  def destination
    @destination||= container.consignees_or_shippers_info(companies).first
  end

  def rail_road
    @rail_road||= container.terminals_info(companies).first.try(:rail_road)
  end

  def customer
    @customer||= container.customer
  end

  def customer_quotes
    return SpotQuote.none unless valid?
    instant_customer_quote
    zip_code = destination.try(:zip_code)
    city_state = [destination.try(:address_city), destination.try(:abbrev)].join(", ")
    relation = SpotQuote.unscoped.to_review.where("customer_id = ? AND dest_address REGEXP ?", customer.id, "#{zip_code}|#{city_state}")
    relation = container.triaxle ? relation.triaxle_weight : relation.legal_weight
    relation = relation.order("instant_date DESC, overrided_at DESC, expired_date DESC")
    relation
  end

  def stack_quotes
    return Container.none unless valid?
    customer.containers
            .includes(receivable_container_charges: :chargable)
            .default.confirmed
            .created_at_from(180.days.ago.to_date)
            .joins(:operations, :receivable_container_charges)
            .where("operations.company_id = ? AND containers.id != ?", destination.try(:id), container.id.to_i)
            .distinct
  end

  def build_charges
    case target
    when SpotQuote
      target.save_as_receivables(container, save_mode)
    when Container
      method = save_mode ? :create : :build
      container.receivable_container_charges.auto_saved.destroy_all if save_mode
      ContainerCharge.where(id: charge_ids).each do |cc|
        attrs = {
          company: cc.company, amount: cc.amount,
          chargable_type: cc.chargable_type, chargable_id: cc.chargable_id, auto_save: true
        }
        container.receivable_container_charges.send(method, attrs)
      end
    end
  end

  def instant_customer_quote
    begin
      SpotQuote.expired_instant.destroy_all
      dest_address = destination.address
      relation = SpotQuote.unscoped.to_review.where("customer_id = ? AND dest_address LIKE ?", container.customer_id, "%#{dest_address}%")
      relation = relation.where(instant_date: Date.today)
      relation = relation.where(rail_road_id: rail_road.id) if rail_road
      relation = container.triaxle ? relation.triaxle_weight : relation.legal_weight
      recent = relation.first
      return recent if recent
      meters = container.customer_mileage
      SpotQuote.create!({
        rail_road_id: rail_road.id,
        ssline_id: container.ssline_id,
        meters: meters*2,
        customer_id: container.customer_id,
        port_id: rail_road.port_id,
        dest_address: dest_address,
        drop_pull: !container.live_load?,
        live_load: true,
        triaxle: container.triaxle,
        cargo_weight: (container.triaxle ? 2 : 1),
        container_type_id: container.container_type_id,
        container_size_id: container.container_size_id,
        instant_date: Date.today
      }) if meters > 0
    rescue => ex
      return false
    end
  end

end
