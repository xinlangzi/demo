class ScheduleTripWorker
  include Sidekiq::Worker

  def perform(id)
    begin
      container = Container.find(id)
      container.calculate_distances
      container.mileage_with_appt
    rescue =>ex
      Rails.logger.error(ex.message)
    end
  end

end