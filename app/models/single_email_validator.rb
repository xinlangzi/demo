class SingleEmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    record.errors.add attribute, (options[:message] || "is not a valid email") unless (value.blank? || value.strip =~ EMAIL_REGEX)
  end
end