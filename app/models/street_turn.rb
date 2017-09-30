class StreetTurn < Tableless
  attr_accessor :source_id, :dest_id, :yard_id, :type

  validates :source_id, :dest_id, :type, presence: true

  after_initialize :init_default_attrs

  def add_error(error)
    errors.add(:base, error)
  end

  def only_chassis?
    self.type.to_sym == :only_chassis
  end

  def source
    @source||= Container.find_by(id: source_id)
  end

  def source_is_import?
    source.is_a?(ImportContainer)
  end

  def dest
    @dest||= Container.find_by(id: dest_id)
  end

  def yard
    @yard||= Yard.find_by(id: yard_id)
  end

  def street_turn_type_for_import
    @iotype||= OperationType.import.find_by(name: 'Street Turn')
  end

  def street_turn_type_for_export
    @eotype||= OperationType.export.find_by(name: 'Street Turn')
  end

  def save!
    Container.transaction do
      raise "Invalid container #{source_id}" unless source
      case type.to_s
      when /chassis_with_container/
        turn_chassis_with_container
      when /only_chassis/
        turn_only_chassis
      end
    end
  end

  def unlink!
    source.update!(street_turn_id: nil, street_turn_type: nil)
  end

  def turn_chassis_with_container
    raise "Please provide an export container" unless dest
    raise "Please provide an export container" unless dest.is_a?(ExportContainer)
    raise "Don't street turn to different hub" if source.hub != dest.hub
    raise "Please provide a yard" unless yard
    raise "No street turn operation type for import was configured." unless street_turn_type_for_import
    raise "No street turn operation type for export was configured." unless street_turn_type_for_export

    source.update!(street_turn_id: dest.id, street_turn_type: :chassis_with_container)
    source.update!(chassis_return_with_container: true)
    last = source.operations.last
    last.update!(operation_type: street_turn_type_for_import, company: yard)

    first = dest.operations.first
    first.update!(operation_type: street_turn_type_for_export, company: yard)
    dest.update!(container_no: source.container_no, chassis_pickup_with_container: true)
  end

  def turn_only_chassis
    raise "Please provide an import or export container" unless dest
    raise "Don't street turn to same container" if source == dest
    raise "Don't street turn to different hub" if source.hub != dest.hub
    raise "Circle street turn is disallowed" if source == dest.street_turn

    source.update!(street_turn_id: dest.id, street_turn_type: :only_chassis)
    source.update!(chassis_return_with_container: nil, chassis_return_company_id: nil)

    dest.update!(chassis_pickup_with_container: nil, chassis_pickup_company_id: nil)
  end

  def street_turn_types
    if source_is_import?
      Container.street_turn_types.clone
    else
      Container.street_turn_types.clone.slice("only_chassis")
    end
  end

  private
  def init_default_attrs
    self.type||= source.try(:street_turn_type)
    self.type||= street_turn_types.keys.first.to_sym
    self.yard_id = nil if only_chassis?
  end

end