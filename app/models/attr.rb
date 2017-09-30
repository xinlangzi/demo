class Attr

  MARK_MAPPINGS = {
    ecco:  { model: "ExportContainer", column: :container_no },
    ecsbn: { model: "ExportContainer", column: :ssline_booking_no },
    icco:  { model: "ImportContainer", column: :container_no },
    icsbn: { model: "ImportContainer", column: :ssline_booking_no },
    icsn: { model: "ImportContainer", column: :seal_no },
    ecsn: { model: "ExportContainer", column: :seal_no }
  }

  def self.duplicates(mark, id, term)
    return [] if term.blank?
    mapping = MARK_MAPPINGS[mark.to_sym]
    mapping[:model].constantize.where("#{mapping[:column].to_s} = ? AND id <> ?", term, id)
  end

  def self.mark(obj, column)
    MARK_MAPPINGS.key({ model: obj.class.to_s, column: column.to_sym})
  end

  def self.check_dups_url(obj, column)
    mark = mark(obj, column)
    "/attrs/#{obj.id.to_i}/dups?mark=#{mark}"
  end
end