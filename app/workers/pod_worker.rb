class PodWorker
  include Sidekiq::Worker

  def perform(id)
    Pod.find(id).save_pdf
  end
end
