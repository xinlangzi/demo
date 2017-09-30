module PaperTrail
  class Version < ::ApplicationRecord
    include PaperTrail::VersionConcern
    scope :keyword, ->(keyword){
      where("versions.object_changes LIKE ?", "%#{keyword.to_s}%")
    }
    scope :desc, ->{ order('id DESC') }
    scope :for_item, ->(item){
      item_id = item.id
      case item.type
      when /Container/
        in_ids = PaperTrail::VersionAssociation.where(foreign_key_name: "container_id").where(foreign_key_id: item_id).select('version_id AS id')
        where('(item_type = ? AND item_id = ?) OR (id IN (?))', 'Container', item_id, in_ids)
      when /Invoice/
        in_ids = PaperTrail::VersionAssociation.where(foreign_key_name: "invoice_id").where(foreign_key_id: item_id).select('version_id AS id')
        where('(item_type = ? AND item_id = ?) OR (id IN (?))', 'Invoice', item_id, in_ids)
      when /Payment/
        in_ids = PaperTrail::VersionAssociation.where(foreign_key_name: "payment_id").where(foreign_key_id: item_id).select('version_id AS id')
        where('(item_type = ? AND item_id = ?) OR (id IN (?))', 'Payment', item_id, in_ids)
      # when /Company/
      #   where('item_type = ? AND item_id = ?', item_type, item_id)
      else
      end
    }

    def self.ransackable_scopes(auth=nil)
      [:keyword]
    end

    def parent
      case item_type
      when 'Company'
        item
      when 'Container'
        item
      when 'ContainerCharge'
        item.container
      when 'Operation'
        item.container
      when 'Truck'
        item.trucker
      when 'TaskComment'
        item.container
      when 'Credit'
        item.invoice
      when 'Adjustment'
        item.invoice
      else
        item
      end rescue nil
    end

    def dataset
      set = event.to_sym == :destroy ? objectset : changeset
      columns_type = item_type.constantize.columns_hash
      set.select do |key, value|
        value.any?(&:present?)
      end.map do |key, value|
        changes = value.map{|v| parse_data(columns_type[key].type, key, v)}
        if changes.map(&:class).include?(Array)
          removed = added = nil
          before = changes.first || []
          after = changes.last || []
          diff = before - after
          removed = "Removed:\n#{diff.join(';')}" if diff.length > 0
          diff = after - before
          added = "Added:\n#{diff.join(';')}" if diff.length > 0
          changes = [removed, added]
        end
        [key,  changes]
      end.to_h
    end

    def parse_data(column_type, key, value)
      case column_type
      when :time
        value.us_time
      when :date
        value.us_date
      when :datetime
        value.to_time.us_datetime
      else
        value = item_type.constantize.const_get("PAPER_TRAIL_TRANSLATION")[key].call(value) rescue value
      end if value
    end

    def who
      whodunnit ? User.find(whodunnit) : 'Public User'
    end

    def objectset
      @objectset||= load_objectset
    end

    private
      def load_objectset
        set = HashWithIndifferentAccess.new(object_deserialized) rescue {}
        onlys = item_type.constantize.paper_trail_options.only
        ignores = item_type.constantize.paper_trail_options.ignore
        set.select do |key, value|
          (onlys.empty? || onlys.include?(key)) && ignores.exclude?(key)
        end.map do |key, value|
          [key, [value, nil]]
        end.to_h
      end
  end

end
