# frozen_string_literal: true

module ResponseHelper
  def success(body)
    # c_response(200, body)
  end

  def no_content
    c_response(204)
  end

  def not_authorized
    c_response(401, "You're not authorized.")
  end

  def not_found(object)
    c_response(404, "Bad request, not found #{object}")
  end

  def forbidden(message)
    # TODO: leave this for backward compatibility, remove it in future
    code = 403
    render json: {
      status: code,
      data: message,
      message: 
    }, status: code
    # end TODO

    # TODO: use this in future
    #   c_response(403, message)
    # end TODO
  end

  def abort(message)
    c_response(500, "Something went wrong. \n #{message}")
  end

  private

  def c_response(code, body = nil)
    render json: {
      status: code.to_i,
      # TODO: leave this field for backward compatibility, remove it in future
      data: { message: body },
      # end TODO
      message: body
    }, status: code
  end
end
