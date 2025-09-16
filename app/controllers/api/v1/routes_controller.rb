module Api
  module V1
    class RoutesController < ApplicationController
      before_action :set_route, only: %i[update show destroy]
      before_action :check_params, only: %i[create update]

      def index
        set_error_code("023")
        routes = Route.filtered.includes(
          %i[cloud_gateway healthcheck routes_services services
             user_middlewares]
        )
        render json: routes, status: :ok
      end

      def show
        set_error_code("024")
        render json: { route: @route }, status: :ok
      end

      def create
        set_error_code("025")
        services = params[:route].delete(:services)
        if params[:route][:healthcheck_enabled]
          healthcheck_params = params[:route].delete(:healthcheck)
        end
        route_params = route_create_params
        if User.current_user.role == "member"
          route_params[:owner] = User.current_user.userid
        end
        Route.transaction do
          @route = Route.create!(route_params)

          if @route.healthcheck_enabled
            @route.create_healthcheck!(
              healthcheck_params.permit(
                :path, :scheme, :hostname, :port, :interval, :timeout, :method,
                :follow_redirects, headers: {}
              )
            )
          end

          name = RoutesService.generate_name
          if services.one?
            RoutesService.create!(
              route:        @route,
              service:      Service.filtered.find_by(id: services.first["id"]),
              balance_type: :loadbalancer,
              value:        nil,
              name:         RoutesService.unique_name(name)
            )

          elsif services.many?
            services.each do |data|
              RoutesService.create!(
                route:        @route,
                service:      Service.filtered.find_by(id: data["id"]),
                balance_type: :weighted,
                value:        data["weight"],
                name:         RoutesService.unique_name(name)
              )
            end
          end

          @route.update_middlewares(middleware_params)
        end
        render json: @route, status: :created
      end

      def update
        set_error_code("026")
        services = @route_params.delete(:services)
        Route.transaction do
          update_certificate
          @route.update(sanitize_params[:route], services)
          if @route.healthcheck_enabled
            if @route.healthcheck
              @route.healthcheck.update!(healthcheck_params)
            else
              @route.create_healthcheck!(healthcheck_params)
            end
          else
            @route.healthcheck&.destroy!
          end
          @route.update_middlewares(middleware_params) if middleware_params
        end
        render json: @route.reload, status: :ok
      end

      def destroy
        set_error_code("027")
        @route.destroy!
      end

      private

      def set_route
        set_error_code("028")
        @route = Route.filtered.find(params[:id])
      end

      def check_params
        @route_params = params[:route]
        render json: @route unless @route_params

        id = @route_params[:cloud_gateway_id]
        return unless id && !CloudGateway.filtered.exists?(id:)

        message = I18n.t("errors.cloud_gateway.record_not_found")
        render_not_found_response(message:, code: "032", data: { message: })
      end

      def update_certificate
        set_error_code("029")
        return unless @route_params.include?(:certificate_id)

        certificate_id = @route_params[:certificate_id]
        if certificate_id.present?
          if Certificate.filtered.exists?(id: certificate_id)
            @route.update!(certificate_id:)
          end
        else
          @route.update!(certificate_id: nil)
        end
      end

      def sanitize_params
        params.permit(route: params_white_list)
      end

      def params_white_list
        %w[name hostname path target_port insecure tls_termination labels
           cloud_gateway_id owner source_proto destination_proto ip_version
           healthcheck_enabled]
      end

      def healthcheck_params
        healthcheck_params = @route_params.delete(:healthcheck)
        healthcheck_params.permit(
          :path, :scheme, :hostname, :port, :interval, :timeout, :method,
          :follow_redirects, headers: {}
        )
      end

      def route_create_params
        params.expect(
          route: %i[name hostname path target_port insecure tls_termination
                    labels cloud_gateway_id owner source_proto destination_proto
                    ip_version certificate_id healthcheck_enabled]
        )
      end

      def middleware_params
        @middleware_params ||=
          @route_params
          .permit(middlewares: [ :type, options: {} ])[:middlewares]
      end
    end
  end
end
