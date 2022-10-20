# frozen_string_literal: true

# AuthHelper
module AuthHelper
  def get_jwt_token(login, password)
    response = RestClient::Request.execute(
      method: :post,
      url: "#{config_n[:url]}/auth/realms/#{config_n[:realm]}/protocol/openid-connect/token",
      payload: request_payload(login, password)
    )
    JSON.parse(response.body)['access_token']
  end

  def request_payload(login, password)
    {
      username: login,
      password: password,
      grant_type: 'password',
      client_id: config_n[:client_id]
    }
  end

  def config_n
    config_template = ERB.new File.read(File.join(Rails.root, "config", "keycloak.yml.erb"))
    YAML.load config_template.result(binding)
  end

  def decoded_token(token = nil)
    JWT.decode(token, Rails.application.config.sso_public_key, false, algorithm: 'RS256')[0]
  rescue JWT::DecodeError
    abort("Unauthorized! Can't decode JWT token!")
  end
end
