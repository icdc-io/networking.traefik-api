# frozen_string_literal: true

require 'json/jwt'
require 'rbac'

class ApplicationController < ActionController::API
  include ResponseHelper
  include AuthHelper
  include Rbac

  before_action :authorize, :authorize_action, except: %i[traefik_config download]

  def authorize
    return not_authorized unless request.authorization

    auth_method, token = request.authorization.split
    case auth_method
    when 'Bearer'
      bearer_auth(token)
    when 'Basic'
      basic_auth(token)
    end
  end

  def authorize_action
    return if Rbac::Authorizer.new('./config/rbac/rbac_routes.yml').role_allows?(request)

    forbidden('You are not authorized to perform this action.')
  end

  def bearer_auth(pure_token)
    token = decoded_token pure_token
    role = fetch_role
    account = fetch_account
    return not_authorized unless validate(token, account, role)

    User.current_user = User.new(userid: token['email'], token: pure_token, account:, role: setup_role(account, role))
  rescue JWT::DecodeError => e
    Rails.logger.warn "Unauthorized! Can't decode JWT token! #{e.message}"
    not_authorized
  end

  def basic_auth(token)
    login, password = Base64.decode64(token).split(':')
    role = fetch_role
    account = fetch_account
    pure_token = get_jwt_token(login, password)
    token = decoded_token pure_token
    return not_authorized unless validate(token, account, role)

    User.current_user = User.new(userid: token['email'], token: pure_token, account:, role: setup_role(account, role))
  rescue JWT::DecodeError => e
    Rails.logger.warn "Unauthorized! Can't decode JWT token! #{e.message}"
    not_authorized
  end

  private

  def fetch_account
    request.headers[ENV.fetch('ACCOUNT_HEADER')]
  end

  def fetch_role
    request.headers[ENV.fetch('ROLE_HEADER')]
  end

  def setup_role(account, role)
    if ENV.fetch('LOCATION_ADMIN_GROUP') == "#{account}.#{role}"
      'location_admin'
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
