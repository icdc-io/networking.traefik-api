module ApiExceptionsHandler
  extend ActiveSupport::Concern

  included do
    around_action :handle_exceptions

    # used to show place where an error occurs (in case of error)
    # format: ENTx
    # ENT -> Error Networking Traefik, x -> order number
    attr_reader :code

    def set_error_code(code) # rubocop:disable Naming/AccessorMethodName
      @code = "ENT#{code}"
    end
  end

  def handle_exceptions
    yield
  rescue ActiveRecord::RecordNotFound => error
    handle_record_not_found(error)
  rescue ActiveModel::ValidationError, ActiveRecord::RecordInvalid, ArgumentError, ActiveRecord::InvalidForeignKey,
         OpenSSL::PKey::RSAError, OpenSSL::X509::CertificateError => error
    handle_validation_error(error)
  rescue ActionController::ParameterMissing => error
    handle_parameter_missing(error)
  rescue => error
    handle_standard_error(error)
  end

  private

  def handle_record_not_found(exception)
    message = I18n.t(error_path(exception))
    render_not_found_response(message:, errors: [ exception ], code:, data: { message: }) # TODO: leave 'data' for backward compatibility, remove it in future
  end

  def handle_validation_error(exception)
    render_error_response(message: I18n.t(locale_path(exception)),
                          errors: [ exception ], status: 422, code:)
  end

  def handle_parameter_missing(exception)
    render_error_response(message: exception.message, status: 400, code:)
  end

  def handle_standard_error(exception)
    log_exception(exception)
    render_error_response(
      message: I18n.t("errors.common.internal_server_error"), errors: [ exception ], status: 500, code:
    )
  end

  def log_exception(exception)
    Rails.logger.error exception.class.to_s
    Rails.logger.error exception.to_s
    Rails.logger.error exception.backtrace.join("\n")
  end

  def error_path(exception)
    exception_model = exception.model.underscore
    exception_type = exception.class.to_s.split("::").last.underscore
    "errors.#{exception_model}.#{exception_type}"
  end

  def locale_path(exception)
    controller_path = params[:controller].tr("/", ".")
    exception_type = exception.class.to_s.split("::").last.underscore
    "controllers.#{controller_path}.#{action_name}.#{exception_type}"
  end
end
