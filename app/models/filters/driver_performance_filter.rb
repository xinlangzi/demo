class DriverPerformanceFilter < Filter

  def actual_appt_range
    { actual_appt_gteq: @from, actual_appt_lteq: @to }
  end

  def cancelled_appt_range
    { issue_date_gteq: @from, issue_date_lteq: @to }
  end

end
