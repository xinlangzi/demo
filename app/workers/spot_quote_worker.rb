class SpotQuoteWorker
  include Sidekiq::Worker

  def perform(json, ids)
    MyMailer.mail_spot_quotes(json, ids).deliver_now
  end
end
