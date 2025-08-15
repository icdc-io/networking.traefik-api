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

jobs = {
  "Load list of services"   => {
    "class"       => "LoadServicesJob",
    "description" => "Load list of services from Compute and store it into database",
    "cron"        => "*/15 * * * *",
    "args"        => []
  },
  "Delete retired services" => {
    "class"       => "DeleteServicesJob",
    "description" => "Itterate over each service and delete retired services",
    "cron"        => "*/15 * * * *",
    "args"        => []
  }
}

Sidekiq::Cron::Job.load_from_hash jobs unless Rails.env.test?
