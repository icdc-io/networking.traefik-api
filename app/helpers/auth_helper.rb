module AuthHelper
  def get_jwt_token(login, password)
    response = RestClient::Request.execute(
      :method => :post,
      :url => "#{config_n[:url]}/auth/realms/#{config_n[:realm]}/protocol/openid-connect/token",
      :payload => {
        :username   => login,
        :password   => password,
        :grant_type => "password",
        :client_id  => config_n[:client_id]
      }
    )
    JSON.parse(response.body)["access_token"]
  end

  def config_n
    YAML.load_file(File.join(Rails.root, "config", "keycloak.yml"))
  end

  def decoded_token(token = nil)
    @@public_key ||= public_key
    JWT.decode(token, @@public_key, false, algorithm: 'RS256')[0]
  rescue JWT::DecodeError
    abort("Unauthorized! Can't decode JWT token!")
  end

  def public_key
    response = RestClient::Request.execute(
      :method => :get,
      :url => "#{config_n[:url]}/auth/realms/#{config_n[:realm]}/protocol/openid-connect/certs"
    )
    JSON.parse(response.body)["keys"].map do |key|
      next unless key["alg"] == "RS256"
      return JSON::JWK.new(key).to_key
    end
    nil
  end
end
