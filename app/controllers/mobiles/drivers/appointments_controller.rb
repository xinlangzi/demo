class Mobiles::Drivers::AppointmentsController < ApplicationController

  def late
    options = { actual_appt_gteq: Date.today.beginning_of_year, actual_appt_lteq: Date.today }
    @lates = current_user.operations.late_by_trucker.search(options).result
  end

  def cancelled
    options = { issue_date_gteq: Date.today.beginning_of_year, issue_date_lteq: Date.today }
    @cancelled_appointments = current_user.cancelled_appointments.search(options).result
  end

end
