class DriverMileSegment < Array
  attr_accessor :container

  class Segment
    attr_accessor :driver, :operations, :drop_pull

    def initialize(operation)
      @driver = operation.trucker
      @operations = [operation]
    end

    def breakpoint?(operation)
      is_drop?(operation) || driver_changed?(operation) || operation.final?
    end

    def drop_pull?
      @operations.first.is_drop? || (@operations.last.after.is_drop? rescue false)
    end

    def is_drop?(operation)
      operation.is_drop?
    end

    def preset?
      @operations.detect(&:preset?)
    end

    def do_prepull?
      @operations.detect(&:do_prepull?)
    end

    def driver_changed?(operation)
      @operations.last.trucker != operation.trucker
    end

    def <<(operation)
      (@operations << operation).uniq!
    end

    def miles
      @operations.map(&:leg_miles).sum
    end

  end

  def initialize(container)
    @container = container
    build_segments
  end

  def <<(segment)
    super.compact!
  end

  def view_segments(visitor)
    case visitor
    when Admin, SuperAdmin
      self
    when Trucker
      select{|segment| segment.driver == visitor }
    else
      []
    end
  end

  def at_segment(operation)
    detect{|segment| segment.operations.include?(operation)}
  end

  def add_last_operation # add last operation to last segment
    last.operations << container.operations.last
  end

  def build_linkeds
    each do |segment|
      origin = segment.operations.first
      while origin.linker
        origin = origin.linker
      end
      dms = DriverMileSegment.new(origin.container)
      at_segment = dms.at_segment(origin)
      segment.operations = at_segment.operations
      while linked = at_segment.operations.last.linked
        dms = DriverMileSegment.new(linked.container)
        at_segment = dms.at_segment(linked)
        segment.operations.push(*at_segment.operations)
      end
    end
  end

  private

  def build_segments
    segment = nil
    container.operations.each do |operation|
      if operation.preset?
        self << segment
        self << Segment.new(operation)
        segment = nil
      elsif operation.do_prepull?
        segment||= Segment.new(operation)
        segment << operation
        self << segment
        segment = nil
      elsif segment&&segment.breakpoint?(operation)
        self << segment
        segment = Segment.new(operation)
      else
        segment||= Segment.new(operation)
        segment << operation
      end
    end
  end

end