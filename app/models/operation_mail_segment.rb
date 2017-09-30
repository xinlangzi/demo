class OperationMailSegment < Array

  attr_accessor :container

  class Segment
    attr_accessor :driver, :operations, :drop_pull

    def initialize(operation)
      @driver = operation.trucker
      @operations = [operation]
    end

    def drop_pull?
      @operations.first.is_drop?
    end

    def is_drop?(operation)
      operation.is_drop?
    end

    def driver_changed?(operation)
      @operations.last.trucker != operation.trucker
    end

    def <<(operation)
      (@operations << operation).uniq!
    end

  end

  def initialize(container)
    @container = container
    build_segments
  end

  def <<(segment)
    super.compact!
  end

  def at_segments(operation)
    ids = operation.is_drop? ? [operation.before.id, operation.id] : [operation.id]
    select{|segment| (segment.operations.map(&:id)&ids).present? }
  end

  def at_segment(operation)
    detect{|segment| segment.operations.include?(operation)}
  end

  def build_linkeds
    each do |segment|
      origin = segment.operations.first
      while origin.linker
        origin = origin.linker
      end
      ops = OperationMailSegment.new(origin.container)
      at_segment = ops.at_segment(origin)
      segment.operations = at_segment.operations
      while linked = at_segment.operations.last.linked
        ops = OperationMailSegment.new(linked.container)
        at_segment = ops.at_segment(linked)
        segment.operations.push(*at_segment.operations)
      end
    end
  end

  private

  def build_segments
    segment = nil
    container.operations.each do |operation|
      if segment&&segment.is_drop?(operation)
        self << segment
        segment = Segment.new(operation)
      elsif segment&&operation.final?
        self << segment
      elsif segment&&segment.driver_changed?(operation)
        self << segment
        segment = Segment.new(operation)
      else
        segment||= Segment.new(operation)
        segment << operation
      end
    end
  end
end