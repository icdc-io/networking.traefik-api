Sidekiq.configure_client do |config|
  config.redis = {
    url:      ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    password: ENV.fetch("REDIS_PASSWORD", nil)
  }
end

Sidekiq.configure_server do |config|
  config.redis = {
    url:      ENV.fetch("REDIS_URL", "redis://localhost:6379/0"),
    password: ENV.fetch("REDIS_PASSWORD", nil)
  }
end
