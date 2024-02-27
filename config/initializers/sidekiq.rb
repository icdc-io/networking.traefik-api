# frozen_string_literal: true

Sidekiq.configure_client do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL'),
    password: ENV.fetch('REDIS_PASSWORD', nil)
  }
end

Sidekiq.configure_server do |config|
  config.redis = {
    url: ENV.fetch('REDIS_URL'),
    password: ENV.fetch('REDIS_PASSWORD', nil)
  }
end

jobs = {
  'Collect data about access to services' => {
    'class' => 'ServicesAccessJob',
    'description' => 'Collect data from Compute and store it into InfluxDB',
    'cron' => '*/15 * * * *',
    'args' => []
  }
}

Sidekiq::Cron::Job.load_from_hash jobs
