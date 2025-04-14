# frozen_string_literal: true

require 'json/jwt'
require 'rbac'

class ApplicationController < ActionController::API
  around_action :switch_locale
  include ApiResponseHandler
  include ApiExceptionsHandler
  include AuthHelper
  include Rbac

  before_action :authorize, :authorize_action, except: %i[traefik_config download]

  def authorize
    set_error_code('001')
    return unauthorized unless request.authorization

    auth_method, token = request.authorization.split
    case auth_method
    when 'Bearer'
      bearer_auth(token)
    when 'Basic'
      basic_auth(token)
    end
  end

  def authorize_action
    set_error_code('002')
    return if Rbac::Authorizer.new('./config/rbac/rbac_routes.yml').role_allows?(request)

    render_forbidden_response(message: I18n.t('controllers.application.forbidden'), code: 'ENT002', data: I18n.t('controllers.application.forbidden')) # TODO: leave 'data' for backward compatibility, remove it in future
  end

  def switch_locale(&)
    set_error_code('003')
    locale = extract_locale_from_accept_language_header || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  private

  def bearer_auth(pure_token)
    set_error_code('004')
    token = decoded_token(pure_token)
    return unless token

    role = fetch_role
    account = fetch_account
    return unauthorized unless validate(token, account, role)

    User.current_user = User.new(userid: token['email'], token: pure_token, account:, role: setup_role(account, role))
  end

  def basic_auth(token)
    set_error_code('005')
    login, password = Base64.decode64(token).split(':')
    pure_token = get_jwt_token(login, password)
    bearer_auth(pure_token)
  end

  def extract_locale_from_accept_language_header
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first
  end

  def fetch_account
    request.headers[ENV.fetch('ACCOUNT_HEADER')]
  end

  def fetch_role
    request.headers[ENV.fetch('ROLE_HEADER')]
  end

  def setup_role(account, role)
    return role unless %w[operator admin].include?(role)

    # if role is an operator or admin
    if ENV.fetch('OPERATOR_GROUP') == "#{account}.#{role}"
      'operator'
    else
      'admin'
    end
  end

  def validate(token, account, role)
    token.dig('external', 'accounts', account, 'roles').include?(role)
  rescue StandardError
    false
  end

  def unauthorized
    set_error_code('006')
    render_unauthorized_response(message: I18n.t('controllers.application.unauthorized'), code: 'ENT001', data: { message: I18n.t('controllers.application.unauthorized') }) # TODO: leave 'data' for backward compatibility, remove it in future
  end
end
