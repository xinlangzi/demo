class MultipleEmailValidator < ActiveModel::EachValidator
  def validate_each(record, attribute, value)
    list = case value
    when String
      emails = value.gsub(/\[|\]|\"|\'/, '').split(",").map(&:strip)
      record.send("#{attribute}=".to_sym, emails.join(","))
      emails
    when Array
      emails = value.map{|item| item.split(",") }.flatten
      record.send("#{attribute}=".to_sym, emails.join(","))
      emails
    else
      []
    end
    record.errors.add attribute, (options[:message] || "is an invalid list of emails") unless list.all?{|email| email.strip =~ EMAIL_REGEX }
  end
end