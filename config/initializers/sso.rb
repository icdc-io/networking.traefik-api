def set_public_key
  response = RestClient::Request.execute(
    method:     :get,
    url:        "#{ENV.fetch('SSO_URL')}/realms/#{ENV.fetch('SSO_REALM')}/protocol/openid-connect/certs",
    verify_ssl: Rails.env.production?
  )

  key = JSON.parse(response.body)["keys"].find { |k| k["alg"] == "RS256" }
  return nil unless key

  JSON::JWK.new(key).to_key
end

Rails.application.secrets.sso_public_key = set_public_key unless Rails.env.test?
