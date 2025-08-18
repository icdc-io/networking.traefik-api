# AuthHelper
module AuthHelper
  def get_jwt_token(login, password)
    response = RestClient::Request.execute(
      method:     :post,
      url:        "#{ENV.fetch('SSO_URL')}/realms/#{ENV.fetch('SSO_REALM')}" \
                  "/protocol/openid-connect/token",
      payload:    request_payload(login, password),
      verify_ssl: Rails.env.production?
    )
    JSON.parse(response.body)["access_token"]
  end

  def request_payload(username, password)
    {
      username:,
      password:,
      grant_type: "password",
      client_id:  ENV.fetch("SSO_CLIENT_ID")
    }
  end

  def decoded_token(token = nil)
    set_error_code("007")
    JWT.decode(token, Rails.application.secrets.sso_public_key, true,
               algorithm: "RS256")[0]
  rescue JWT::DecodeError => error
    render_error_response(
      message: I18n.t("controllers.application.jwt.decode_error"),
      status: 500, code:, errors: [ error ]
    )
    nil
  end
end
