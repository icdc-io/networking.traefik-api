module Authenticator
  def config
    require "yaml"
    config_template = ERB.new(
      Rails.root.join("config/platform_creds.yml.erb").read
    )
    YAML.load config_template.result(binding)
  rescue Errno::ENOENT
    raise "File config/platform_creds.yml.erb didn't created"
  end

  def service_creds(service)
    config.dig("environment", Rails.env, service.downcase)
  end

  def basic_token(service)
    creds = config.dig("environment", Rails.env, service.downcase)
    creds["token"] || Base64.encode64(
      "#{creds['username']}:#{creds['password']}"
    ).strip!
  end
end
