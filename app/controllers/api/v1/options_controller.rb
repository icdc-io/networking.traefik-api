module Api
  module V1
    class OptionsController < ApplicationController
      before_action :set_middleware_type, only: :middlewares

      def middlewares
        set_error_code("033")
        schemes = @middleware_type::USER_MIDDLEWARES.map(&:translated_scheme)
        render json: schemes, status: :ok
      end

      private

      def set_middleware_type
        type = params[:route_type]
        return @middleware_type = Middleware unless type

        unless %w[http tcp].include?(type)
          return render_error_response(
            message: I18n.t("controllers.api.v1.options.middlewares.invalid_route_type"),
            code:    "ENT034"
          )
        end

        @middleware_type = "Middleware::#{type.capitalize}".constantize
      end
    end
  end
end
