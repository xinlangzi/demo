class ContainerFilter < Filter

  def sql_conditions(scoped)
    scoped = scoped.where(customer_id: customer_id) unless customer_id.blank?
    scoped = scoped.joins(:operations).where("operations.trucker_id = ?", trucker_id) unless trucker_id.blank?
    scoped = scoped.where("delivered_date >= ?", from.to_datetime) unless from.blank?
    scoped = scoped.where("delivered_date < ?", to.to_datetime + 1) unless to.blank?
    scoped
  end

  def set_interval_of_time(date_hash)
    if (year = date_hash[:year_from]) && (month = date_hash[:month_from]) && !year.blank? && !month.blank?
      month = (month.to_i < 10 ? ("0" + month) : month)
      self.from = (year + month + "01").to_datetime
    end
    if (year = date_hash[:year_to]) && (month = date_hash[:month_to]) && !year.blank? && !month.blank?
      month = (month.to_i < 10 ? ("0" + month) : month)
      self.to = (year + month + "01").to_datetime
      self.to = Date.today if self.to > Date.today
    end
  end

end