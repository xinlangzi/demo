class AuditChassis

  def self.analyse(data)
    records = []
    rows = CSV.parse(data)
    rows.shift
    rows.each do |row|
      chassis_no = row[0]
      row[1].gsub!(/-/, '') rescue nil
      row[2].gsub!(/-/, '') rescue nil
      row[3] = convert_date(row[3])
      row[4] = convert_date(row[4])
      row[5] = convert_date(row[5])
      row[6] = convert_date(row[6])
      row[-3] = row[-3].to_s.gsub(/\$/, '')
      row[-2] = row[-2].to_s.gsub(/\$/, '')
      row[-1] = row[-1].to_s.gsub(/\$/, '')

      marks = []
      if row[-1].to_f == 0
        records << row + [nil]*6
        records.last << marks.uniq
      else
        container_nos = row[1..2].uniq.compact.remove_empty
        containers = []
        if container_nos.empty?
          containers << smart_container(chassis_no, nil, marks)
        else
          container_nos.each do |container_no|
            containers << smart_container(chassis_no, container_no, marks)
          end
        end
        containers.compact!
        if containers.empty?
          records << row + [nil]*6
          records.last << marks.uniq
        else
          extras = []
          containers.each do |container|
            charges = chassis_charges(container)
            if charges.empty?
              extras << [container.id, nil, nil, nil, nil, nil]
            else
              charges.each do |charge|
                extra = []
                invoice = charge.line_item.invoice rescue nil
                extra << container.id
                extra << charge.try(:amount)
                extra << charge.try(:company)
                extra << charge.try(:details)
                extra << invoice.try(:number)
                extra << container.delivered_date.try(:us_date)
                extras << extra
              end
            end
          end
          if extras.empty?
            records << row + [nil]*6
            records.last << marks.uniq
          else
            records << row.clone + extras.shift
            records.last << marks.uniq
            extras.each do |extra|
              records << [nil]*row.length + extra
              records.last << marks.uniq
            end
          end
        end

      end
    end
    records
  end

  def self.rail_chassis
    @rail_chassis||= Accounting::Category.cost.for_container.find_by(name: 'Rail Chassis')
  end

  def self.chassis_charges(container)
    container.payable_container_charges
             .where(chargable_type: 'Accounting::Category', chargable_id: rail_chassis.try(:id))
              # .where(line_item_id: nil)
  end

  def self.smart_container(chassis_no, container_no, marks)
    container = nil
    if container_no
      container = Container.search(chassis_no_cont: chassis_no, container_no_cont: container_no).result.order("delivered_date DESC").first
      marks << :matched_chassis_no << :matched_container_no if container
      container||= Container.search(container_no_cont: container_no).result.order("delivered_date DESC").first
      marks << :matched_container_no if container
    else
      container = Container.search(chassis_no_cont: chassis_no).result.order("delivered_date DESC").first
      marks << :matched_chassis_no if container
    end
    if container.nil? && (chassis_no[4] =~/([\D]+)0(\d{5,})/)
      container = smart_container("#{$1}#{$2}", container_no, marks)
    end
    container
  end

  def self.convert_date(date)
    case date
    when /(\d+)-(\D+)-(\d+)/
      Date.parse(date).strftime('%-m/%-d')
    else
      date
    end
  end

end