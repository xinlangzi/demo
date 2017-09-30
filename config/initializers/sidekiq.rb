Sidekiq.configure_server do |server_config|
  server_config.redis = {
    url: 'redis://localhost:6379/0',
    namespace: Rails.application.secrets.redis_namespace
  }
end

Sidekiq.configure_client do |client_config|
  client_config.redis = {
    url: 'redis://localhost:6379/0',
    namespace: Rails.application.secrets.redis_namespace
  }
end
