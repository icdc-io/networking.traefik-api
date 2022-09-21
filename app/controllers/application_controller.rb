require 'json/jwt'
require 'rbac'

class ApplicationController < ActionController::API
  include ResponseHelper
  include AuthHelper
  include Rbac

  before_action :authorize, :authorize_action, except: [:traefik_config, :download]

  def authorize
    return not_authorized unless request.authorization
    auth_method, token = request.authorization.split(' ')
    case auth_method
    when 'Bearer'
      bearer_auth(token)
    when 'Basic'
      basic_auth(token)
    end
  end

  def authorize_action
    forbidden("You are not authorized to perform this action.") unless Rbac::Authorizer.new('./config/rbac/rbac_routes.yml').role_allows?(request)
  end

  def bearer_auth(pure_token)
    token = decoded_token pure_token
    role = request.headers['x-icdc-role']
    account = request.headers['x-icdc-account']
    return not_authorized unless validate(token, account, role)

    User.current_user = User.new(userid: token['email'], token: pure_token, account: account, role: setup_role(account, role))
  end

  def basic_auth(token)
    login, password = Base64.decode64(token).split(':')
    role = request.headers['x-icdc-role']
    account = request.headers['x-icdc-account']
    pure_token = get_jwt_token(login, password)
    token = decoded_token pure_token
    return not_authorized unless validate(token, account, role)

    User.current_user = User.new(userid: token['email'], token: pure_token, account: account, role: setup_role(account, role))
  end

  private

  def setup_role(account, role)
    if ENV['LOCATION_ADMIN_GROUP'] == "#{account}.#{role}"
      "location_admin"
    else 
      role
    end
  end

  def validate(token, account, role)
    token.dig('external', 'accounts', account, 'roles').include?(role)
  rescue StandardError
    false
  end
end
