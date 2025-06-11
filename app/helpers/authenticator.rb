# frozen_string_literal: true

module Authenticator
  def config
    require 'yaml'
    config_template = ERB.new Rails.root.join('config/icdc_credentials.yml.erb').read
    YAML.load config_template.result(binding)
  rescue Errno::ENOENT
    raise "File config/icdc_credentials.yml.erb didn't created"
  end

  def service_creds(service)
    config.dig('environment', ENV.fetch('RAILS_ENV', nil), service.downcase)
  end

  def basic_token(service)
    creds = config.dig('environment', ENV.fetch('RAILS_ENV', nil), service.downcase)
    creds['token'] || Base64.encode64("#{creds['username']}:#{creds['password']}").strip!
  end
end
