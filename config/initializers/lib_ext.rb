module Miles

  def miles
    (self/METER_TO_MILE).round(2) rescue ''
  end

  def weight_factor
    self >= 200 ? 1.0 : (self > 0 ? 0.5 : 0.0) rescue 0.0
  end

end

module DateExtend
  def us_datetime
    self.strftime("%m/%d/%Y %I:%M%p")
  end

  def us_date
    self.strftime("%m/%d/%Y")
  end

  def us_time
    self.strftime("%I:%M%p")
  end

  def us_abd
    self.strftime("%a, %b %d")
  end

  def ymd
    self.strftime("%Y-%m-%d")
  end

  def ymdhm
    self.strftime("%Y-%m-%d %H:%M")
  end

  def ymdhmp
    self.strftime("%Y-%m-%d %I:%M%p")
  end

  def prior_business_day(num)
    return self if num == 0
    yesterday.prior_business_day(yesterday.weekend? || Holiday.include?(yesterday) ? num : num - 1)
  end

  def weekend?
    [6, 0].include?(wday)
  end

end

class Array

  def count_dups
    self.each_with_object(Hash.new(0)) { |o, h| h[o] += 1 }
  end

  def remove_empty
    self.delete_if{|v| v.blank? }
  end

end

class FalseClass
  def to_i
    0
  end

  def to_boolean
    false
  end
end

class TrueClass
  def to_i
    1
  end

  def to_boolean
    true
  end

end

class NilClass
  include Miles
  def precision1
    0.0
  end

  def precision2
    0.00
  end

  def remove_empty
    nil
  end

  def to_boolean
    false
  end
end

class Numeric
  include Miles
end

class Fixnum

  def precision1
    sprintf('%.01f', self)
  end

  def precision2
    sprintf('%.02f', self)
  end

  def big_decimal
    BigDecimal(self.to_s)
  end
end

class Float

  def precision1
    sprintf('%.01f', self)
  end

  def precision2
    sprintf('%.02f', self)
  end

  def big_decimal
    BigDecimal(self.to_s)
  end
end

class BigDecimal

  def precision1
    sprintf('%.01f', self)
  end

  def precision2
    sprintf('%.02f', self)
  end

  def big_decimal
    self
  end
end

class Hash

  def values_empty?
    values.join("").blank?
  end

  def remove_empty
    self.delete_if{ |k, v| v.to_s.empty? }
  end

  def insert(index, key, value)
    array = self.to_a
    self.clear
    array.insert(index, [key, value]).each{|comb| self[comb[0]] = comb[1]}
    self
  end

  def values_for(key)
    result = []
    result << self[key]
    self.values.each do |hash_value|
      values = [hash_value] unless hash_value.is_a? Array
      values.each do |value|
        result += value.values_for(key) if value.is_a? Hash
      end
    end
    result.compact
  end

  def method_missing(method, *opts)
    m = method.to_s
    if self.has_key?(m)
      return self[m]
    elsif self.has_key?(m.to_sym)
      return self[m.to_sym]
    end
    super
  end

end

class Time
  include DateExtend
end

class DateTime
  include DateExtend
end

class Date
  include DateExtend

  def to_i
    self.to_datetime.to_i
  end
end

class String
  def strftime(format)
    self.to_datetime.strftime(format)
  end

  def big_decimal
    BigDecimal(self)
  end

  def self.random_code(len=10)
    SecureRandom.hex(len)
  end

  def to_boolean
    return true if self =~ (/^(true|t|yes|y|1)$/i)
    return false if self.empty? || self =~ (/^(false|f|no|n|0)$/i)
    raise ArgumentError.new "invalid value: #{self}"
  end
end

module Enumerable
  def count_by(&block)
    Hash[group_by(&block).map { |key,vals| [key, vals.size] }]
  end
end

class Exception
  def to_pretty
    self.class.name + ": " + self.message  + "\n" + self.backtrace.join("\n")
  end
end

class ActiveSupport::TimeWithZone

  def hm
    strftime("%H:%M")
  end

end
