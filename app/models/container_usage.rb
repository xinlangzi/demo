class ContainerUsage

  attr_accessor :name

  def initialize(name)
    @name = name
  end

  def self.all
    OperationType.required_docs.map(&:container_type).sort.uniq.map{|name| self.new(name)}
  end

  def operation_types
    OperationType.where({container_type: name})
  end
end