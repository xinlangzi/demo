module Checkable
  module Status
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods

      def constant_status_mapping
        "#{self.to_s.titleize.gsub(/\s/, '_').upcase}_STATUSES_MAPPING"
      end

      def super_constant_status_mapping
        "#{superclass.to_s.titleize.gsub(/\s/, '_').upcase}_STATUSES_MAPPING"
      end

      def check_status(*args)
        if superclass == ActiveRecord::Base
          const_set(constant_status_mapping, {}) unless const_defined?(constant_status_mapping)
          const_get(constant_status_mapping)[args[0]] = args[1]
        else
          const_set(super_constant_status_mapping, {}) unless const_defined?(super_constant_status_mapping)
          const_set(constant_status_mapping, const_get(super_constant_status_mapping).clone) unless const_defined?(constant_status_mapping)
          const_get(constant_status_mapping)[args[0]] = args[1] unless args.empty?
        end
      end
    end
    def check_statuses
      warnings = []
      self.class.const_get(self.class.constant_status_mapping).each do |method, options|
        obj = self.send(method)
        begin
          _false = options[:should] ? obj.send(options[:should]) : obj
          warnings << options[:otherwise] if !_false
        rescue Exception => ex
          warnings << ex.message
        end unless obj.nil?
      end
      warnings.uniq
    end
  end
end
ActiveRecord::Base.send(:include, Checkable::Status)