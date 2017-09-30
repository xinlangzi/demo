class EdiWorker
  include Sidekiq::Worker

  sidekiq_options queue: :edi_queue, backtrace: true

  def perform(provider_id)
    Edi::Provider.find(provider_id).process_queue
  end
end
