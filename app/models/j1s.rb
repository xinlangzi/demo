class J1s

  CHASSIS_PICKUP = 'chassis_pickup'
  CHASSIS_RETURN = 'chassis_return'

  J1 = Struct.new(:object, :container_id, :action_name, :column_name, :company, :pos, :locked, :owner_id) do
    def to_s
      [object.class.table_name.classify, object.id, column_name].join('-')
    end
  end

  def self.missing_chassis_pickup_doc
    Container.select("containers.id, operations.trucker_id AS owner_id, 0 AS pos")
             .joins("LEFT OUTER JOIN operations ON operations.container_id = containers.id AND pos = 1")
             .joins("LEFT OUTER JOIN images ON images.imagable_type = 'Container' AND images.imagable_id = containers.id AND images.column_name = '#{CHASSIS_PICKUP}'")
             .where("IFNULL(containers.waive_docs, false) = FALSE AND chassis_pickup_with_container != true")
             .where("containers.appt_date < ?", Date.today)
             .where("images.id IS NULL")
             .distinct
  end

  def self.pending_chassis_pickup_doc
    Container.select("containers.id, operations.trucker_id AS owner_id, 0 AS pos")
             .joins("LEFT OUTER JOIN operations ON operations.container_id = containers.id AND pos = 1")
             .joins("LEFT OUTER JOIN images ON images.imagable_type = 'Container' AND images.imagable_id = containers.id AND images.column_name = '#{CHASSIS_PICKUP}'")
             .where("IFNULL(containers.waive_docs, false) = FALSE AND chassis_pickup_with_container != true")
             .where("images.id IS NULL OR images.status IN (0, 2)")
             .distinct
  end

  # last second operation with driver
  def self.missing_chassis_return_doc
    Container.select("containers.id, operations.trucker_id AS owner_id, operations_count + 1 AS pos")
             .joins("LEFT OUTER JOIN operations ON operations.container_id = containers.id AND pos = operations_count - 1")
             .joins("LEFT OUTER JOIN images ON images.imagable_type = 'Container' AND images.imagable_id = containers.id AND images.column_name = '#{CHASSIS_RETURN}'")
             .where("IFNULL(containers.waive_docs, false) = FALSE AND chassis_return_with_container != true")
             .where("images.id IS NULL")
             .where("containers.appt_date < ?", Date.today)
             .distinct
  end

  def self.pending_chassis_return_doc
    Container.select("containers.id, operations.trucker_id AS owner_id, operations_count + 1 AS pos")
             .joins("LEFT OUTER JOIN operations ON operations.container_id = containers.id AND pos = operations_count - 1")
             .joins("LEFT OUTER JOIN images ON images.imagable_type = 'Container' AND images.imagable_id = containers.id AND images.column_name = '#{CHASSIS_RETURN}'")
             .where("IFNULL(containers.waive_docs, false) = FALSE AND chassis_return_with_container != true")
             .where("images.id IS NULL OR images.status IN (0, 2)")
             .distinct
  end

  def self.missing(user)
    j1s = []
    J1s.missing_chassis_pickup_doc.having("owner_id = ?", user.id).each do |m|
      object = Container.find(m.id)
      j1s << J1.new(object, object.id, 'Chassis Pickup', CHASSIS_PICKUP, object.chassis_pickup_company, m.pos, object.lock)
    end
    J1s.missing_chassis_return_doc.having("owner_id = ?", user.id).each do |m|
      object = Container.find(m.id)
      j1s << J1.new(object, object.id, 'Chassis Return', CHASSIS_RETURN, object.chassis_return_company, m.pos, object.lock)
    end
    Operation.missing_doc_for(user).each do |m|
      object = Operation.find(m.id)
      container = object.container
      j1s << J1.new(object, object.container_id, object.operation_type.name, nil, object.company, m.pos, container.lock)
    end
    j1s.sort_by{|s| [s.container_id, s.pos] }
  end

  def self.next_missing(user, current)
    j1s = missing(user).reject(&:locked)
    index = j1s.find_index{|j1| j1.to_s == current } || -1
    _next = j1s[(index + 1)%j1s.length] #circle
    _next.to_s != current ? _next : nil # exclude current one
  end

  def self.pending(user)
    j1s = []
    J1s.pending_chassis_pickup_doc.having("owner_id = ?", user.id).each do |m|
      object = Container.find(m.id)
      j1s << J1.new(object, object.id, 'Chassis Pickup', CHASSIS_PICKUP, object.chassis_pickup_company, m.pos, object.lock)
    end
    J1s.pending_chassis_return_doc.having("owner_id = ?", user.id).each do |m|
      object = Container.find(m.id)
      j1s << J1.new(object, object.id, 'Chassis Return', CHASSIS_RETURN, object.chassis_return_company, m.pos, object.lock)
    end
    Operation.pending_doc_for(user).each do |m|
      object = Operation.find(m.id)
      container = object.container
      j1s << J1.new(object, object.container_id, object.operation_type.name, nil, object.company, m.pos, container.lock)
    end
    j1s.sort_by{|s| [s.container_id, s.pos] }
  end

  def self.number_of_missing
    Rails.cache.fetch(:j1s_number_of_missing) || [].tap do |summary|
      J1s.missing_chassis_pickup_doc.each do |m|
        summary << J1.new(nil, m.id, nil, nil, nil, nil, nil, m.owner_id)
      end
      J1s.missing_chassis_return_doc.each do |m|
        summary << J1.new(nil, m.id, nil, nil, nil, nil, nil, m.owner_id)
      end
      Operation.missing_doc.each do |m|
        summary << J1.new(nil, m.container_id, nil, nil, nil, nil, nil, m.owner_id)
      end
      Rails.cache.write(:j1s_number_of_missing, summary, expires_in: 5.minutes)
    end
  end

  def self.number_of_pending
    Rails.cache.read(:j1s_number_of_pending) || [].tap do |summary|
      J1s.pending_chassis_pickup_doc.each do |m|
        summary << J1.new(nil, m.id, nil, nil, nil, nil, nil, m.owner_id)
      end
      J1s.pending_chassis_return_doc.each do |m|
        summary << J1.new(nil, m.id, nil, nil, nil, nil, nil, m.owner_id)
      end
      Operation.pending_doc.each do |m|
        summary << J1.new(nil, m.container_id, nil, nil, nil, nil, nil, m.owner_id)
      end
      Rails.cache.write(:j1s_number_of_pending, summary, expires_in: 5.minutes)
    end
  end

  def self.pending_by?(user, ids)
    ids = Array(ids)
    container_ids = number_of_pending.select{|j1|
      j1.owner_id == user.id
    }.map(&:container_id).uniq
    (container_ids & ids).present?
  end

  def self.by_operations(options={})
    options.remove_empty
    options[:from]||= Date.today - 7.days
    options[:to]||= Date.today
    operation_time =<<EOF
CASE
WHEN imagable_type = 'Operation' THEN operations.operated_at
WHEN column_name = 'chassis_pickup' THEN containers.chassis_pickup_at
WHEN column_name = 'chassis_return' THEN containers.chassis_return_at
END
EOF
    trucker_column =<<EOF
CASE
WHEN imagable_type = 'Operation' THEN IF(operations.pos = 1, operations.trucker_id, o0.trucker_id)
WHEN column_name = 'chassis_pickup' THEN o1.trucker_id
WHEN column_name = 'chassis_return' THEN o2.trucker_id
END
EOF

    container_id =<<EOF
CASE
WHEN imagable_type = 'Operation' THEN operations.container_id
WHEN column_name = 'chassis_pickup' THEN containers.id
WHEN column_name = 'chassis_return' THEN containers.id
END
EOF

    operation_pos =<<EOF
CASE
WHEN imagable_type = 'Operation' THEN operations.pos
WHEN column_name = 'chassis_pickup' THEN 0
WHEN column_name = 'chassis_return' THEN 100
END
EOF
    relation = Image.joins("LEFT OUTER JOIN operations ON images.imagable_id = operations.id AND images.imagable_type = 'Operation'")
                    .joins("LEFT OUTER JOIN containers ON images.imagable_id = containers.id AND images.imagable_type = 'Container' AND images.column_name IN ('chassis_pickup', 'chassis_return')")
                    .joins("LEFT OUTER JOIN operations o0 ON o0.pos + 1 = operations.pos AND o0.container_id = operations.container_id")
                    .joins("LEFT OUTER JOIN operations o1 ON o1.container_id = containers.id AND o1.pos = 1")
                    .joins("LEFT OUTER JOIN operations o2 ON o2.container_id = containers.id AND o2.pos = containers.operations_count - 1")
                    .where("#{operation_time.chop} BETWEEN ? AND ?", options[:from].to_datetime, options[:to].to_datetime + 1)
                    .order("#{operation_time.chop} ASC, #{container_id.chop} ASC, #{operation_pos.chop} ASC")
    relation = relation.where("#{trucker_column.chop} = ?", options[:trucker_id]) if options[:trucker_id]
    relation
  end
end
