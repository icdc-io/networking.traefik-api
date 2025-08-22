require "rbac"

class ApplicationController < ActionController::API
  include ApiResponseHandler
  include ApiExceptionsHandler
  include Rbac

  around_action :switch_locale
  before_action :authorize, :authorize_action

  def authorize
    set_error_code("001")

    username = request.headers["X-Auth-User"]
    account = request.headers["X-Auth-Account"]
    role = request.headers["X-Auth-Role"]

    return unauthorized unless username && account && role

    User.current_user = User.new(userid: username, account:, role:)
  end

  def authorize_action
    set_error_code("002")
    unless Rbac::Authorizer.new(
      ENV.fetch("ROUTES_MAP_FILE", "./config/rbac/rbac_routes.yml")
    ).role_allows?(request)
      render_forbidden_response(
        message: I18n.t("controllers.application.forbidden"), code:,
        data: I18n.t("controllers.application.forbidden")
      ) # TODO: leave 'data' for backward compatibility, remove it in future
    end
  end

  def switch_locale(&)
    set_error_code("003")
    locale = extract_locale_from_accept_language_header || I18n.default_locale
    I18n.with_locale(locale, &)
  end

  private

  def extract_locale_from_accept_language_header
    request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first
  end

  def unauthorized
    set_error_code("006")
    render_unauthorized_response(
      message: I18n.t("controllers.application.unauthorized"), code:,
      data: { message: I18n.t("controllers.application.unauthorized") }
    ) # TODO: leave 'data' for backward compatibility, remove it in future
  end
end
