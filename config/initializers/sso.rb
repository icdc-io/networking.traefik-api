# frozen_string_literal: true

def set_public_key
  response = RestClient::Request.execute(
    method: :get,
    url: "#{ENV['SSO_URL']}/realms/#{ENV['SSO_REALM']}/protocol/openid-connect/certs"
  )
  JSON.parse(response.body)['keys'].map do |key|
    next unless key['alg'] == 'RS256'

    return JSON::JWK.new(key).to_key
  end
  nil
end

Rails.application.config.sso_public_key = set_public_key
