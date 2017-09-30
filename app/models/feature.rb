class Feature < ApplicationRecord

  serialize :value
  validates :key, presence: true, uniqueness: true

  def self.method_missing(method_name, *args, &block)
    Feature.where(key: method_name.to_s.gsub(/\??/, "")).first_or_create.value
  end
end
