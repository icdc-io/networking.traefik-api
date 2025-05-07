# frozen_string_literal: true

module ApiResponseHandler
  extend ActiveSupport::Concern

  def render_error_response(message:, code:, status: 422, errors: [], data: nil)
    render json: { message:, status:, code:, errors:, data: }, status:
  end

  def render_not_found_response(message:, code:, errors: [], data: {})
    render_error_response(message:, status: 404, code:, errors:, data:)
  end

  def render_unauthorized_response(message:, code:, data: {})
    render_error_response(message:, status: 401, code:, data:)
  end

  def render_forbidden_response(message:, code:, data:)
    render_error_response(message:, status: 403, code:, data:)
  end
end
