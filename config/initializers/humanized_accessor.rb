module HumanizedAccessor
  def self.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    def humanize_decimal_accessor(*fields)
      include ActionView::Helpers::NumberHelper
      fields.each do |field|
        define_method("#{field}_decimal_humanized") do
          number_with_delimiter(read_attribute(field.to_sym))
        end

        define_method("#{field}_decimal_humanized=") do |val|
          write_attribute(field.to_sym, BigDecimal(val.to_s.gsub(/[^0-9\.]/, '')))
        end
      end
    end
  end
end
ActiveRecord::Base.send(:include, HumanizedAccessor)