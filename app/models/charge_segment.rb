class ChargeSegment < Array
  attr_accessor :container, :charges

  class Segment < Struct.new(:company, :charges, :total)
  end

  def initialize(container, charges)
    @container = container
    @charges = charges
    build_segments
  end

  def <<(segment)
    super.compact!
  end

  private

  def build_segments
    dms = DriverMileSegment.new(@container)
    @charges.where(operation_id: nil).group_by(&:company).each do |company, charges|
      self << Segment.new(company, charges, charges.sum(&:amount))
    end # No Leg Charge
    dms.add_last_operation
    dms.each do |dm|
      charges = @charges.where(operation_id: dm.operations.map(&:id))
      self << Segment.new(dm.driver, charges, charges.map(&:amount).sum) unless charges.empty?
    end
  end
end