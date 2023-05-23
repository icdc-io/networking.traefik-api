# frozen_string_literal: true

# AuthHelper
module AuthHelper
  def get_jwt_token(login, password)
    response = RestClient::Request.execute(
      method: :post,
      url: "#{ENV['SSO_URL']}/auth/realms/#{ENV['SSO_REALM']}/protocol/openid-connect/token",
      payload: request_payload(login, password)
    )
    JSON.parse(response.body)['access_token']
  end

  def request_payload(login, password)
    {
      username: login,
      password: password,
      grant_type: 'password',
      client_id: ENV['SSO_CLIENT_ID']
    }
  end

  def decoded_token(token = nil)
    JWT.decode(token, Rails.application.config.sso_public_key, false, algorithm: 'RS256')[0]
  rescue JWT::DecodeError
    abort("Unauthorized! Can't decode JWT token!")
  end
end