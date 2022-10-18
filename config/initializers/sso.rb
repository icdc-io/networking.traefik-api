# frozen_string_literal: true

def config_n
  config_template = ERB.new File.new(File.join(Rails.root, "config", "keycloak.yml")).read
  YAML.load config_template.result(binding)
end

def set_public_key
  response = RestClient::Request.execute(
    method: :get,
    url: "#{config_n[:url]}/auth/realms/#{config_n[:realm]}/protocol/openid-connect/certs"
  )
  JSON.parse(response.body)['keys'].map do |key|
    next unless key['alg'] == 'RS256'

    return JSON::JWK.new(key).to_key
  end
  nil
end

Rails.application.config.sso_public_key = set_public_key
