class Mobiles::Drivers::PerformancesController < ApplicationController

  def index
    @filter = DriverPerformanceFilter.new({ from: Date.today.beginning_of_year, to: Date.today })
    operations = Operation.search(@filter.actual_appt_range).result.where(trucker: current_user)
    @move_stats = Operation.move_stats(operations)
    @work_stats = Trucker.work_stats([current_user], @filter.from, @filter.to)
    @cancelled_count = CancelledAppointment.unscoped.where(trucker: current_user).search(@filter.cancelled_appt_range).result.count
  end

end
