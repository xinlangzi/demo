class NestedAttributesUniquenessValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    nests = value.reject(&:_destroy)
    scope = options[:scope]
    unless nests.map{|nest| scope.map{|s| nest.send(s)}}.uniq.size == nests.size
      record.errors[attribute.to_s.singularize.titleize] << "must be unique."
    end
  end
end