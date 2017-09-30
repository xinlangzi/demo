module Conversion
  extend ActiveSupport::Concern

  module ClassMethods

    def nospace(*attributes)
      return unless connection.data_source_exists?(table_name)
      cols = extract_columns(attributes)
      before_validation do
        cols.each do |col|
          send(col).gsub!(/\s+/, '') rescue nil
        end
      end
    end

    def uppercase(*attributes)
      return unless connection.data_source_exists?(table_name)
      cols = extract_columns(attributes)
      before_validation do
        cols.each do |col|
          send(col).upcase! rescue nil
        end
      end
    end

    def titleize(*attributes)
      return unless connection.data_source_exists?(table_name)
      cols = extract_columns(attributes)
      before_validation do
        cols.each do |col|
          send("#{col}=", send(col).titleize)  rescue nil
        end
      end
    end

    private
      def extract_columns(attributes)
        area = attributes.first
        case area
        when :all
          # uppercase :all
          # uppercase :all, except: [:address]
          area, hash = attributes
          hash||={}
          except = (hash[:except] || []).map(&:to_s)
          cols = self.columns.select{|c| except.exclude?(c.name)}.select{|c| [:string, :text].include?(c.type)}.map(&:name)
        else
          # uppercase :first_name, :last_name
          cols = attributes.map(&:to_s)
          cols.each do |col|
            raise "Invalid column: #{col}" unless self.columns.map(&:name).include?(col)
          end
        end
        cols
      end
  end

end

# DEPRECATION WARNING: Time columns will become time zone aware in Rails 5.1. This
# still causes `String`s to be parsed as if they were in `Time.zone`,
# and `Time`s to be converted to `Time.zone`.

# To keep the old behavior, you must add the following to your initializer:

#     config.active_record.time_zone_aware_types = [:datetime]

# To silence this deprecation warning, add the following:

#     config.active_record.time_zone_aware_types = [:datetime, :time]
#  (called from block in nospace at /Users/xinlangzi/workspace/tz/app/models/concerns/conversion.rb:21)
