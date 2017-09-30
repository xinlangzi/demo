require 'open-uri'
module BaseRate

  extend ActiveSupport::Concern

  def self.import(url)
    ret = "Base Rates are imported successfully!"
    begin
      json = JSON::parse(open(url).read)
      json.each do |name, records|
        klass = name.classify.constantize
        klass.destroy_all
        records.each do |attrs|
          klass.new(attrs).save(validate: false)
        end
      end
    rescue =>ex
      ret = ex.message
    end
    ret
  end

  def self.copy(from, to)
    return if from == to
    ApplicationRecord.transaction do
      has_many = [:mile_rates, :customer_rates, :driver_rates, :customer_drop_rates, :driver_drop_rates]
      has_many.each do |name|
        to.send(name).destroy_all
        from.send(name).each do |obj|
          obj = to.send(name).build(obj.attributes.except("id", "hub_id"))
          obj.save(validate: false)
        end
      end
    end
  end

  included do
    validates :miles, uniqueness: { scope: :hub_id }, presence: true
    default_scope { order("miles ASC") }
  end

  module ClassMethods

    def interpolate(hub, miles)
      before = after = nil
      for_hub(hub).detect do |obj|
        miles < (after = obj).miles ? true : (before = obj).miles.nil?
      end
      return before, after
    end

    def bulk_save(hub, options={})
      for_hub(hub).delete_all
      objs = (options||{}).collect do |id, attrs|
        create(attrs.merge(hub_id: hub.id))
      end
      build_rate0(hub)
      objs
    end

    private
      def build_rate0(hub)
        if for_hub(hub).where(miles: 0).empty?&&for_hub(hub).first.present?
          obj = for_hub(hub).first.dup
          obj.miles = 0
          obj.save(validate: false)
        end
      end
  end

end

