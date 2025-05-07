# frozen_string_literal: true

module Api
  module V1
    class RoutesController < ApplicationController
      before_action :set_route, only: %i[update show destroy]
      before_action :check_params, only: %i[create update]

      def index
        set_error_code('024')
        render json: Route.filtered, status: :ok
      end

      def show
        set_error_code('025')
        render json: { route: @route }, status: :ok
      end

      def create
        set_error_code('026')
        services = params[:route].delete(:services)
        healthcheck_params = params[:route].delete(:healthcheck) if params[:route][:healthcheck_enabled]
        route_params = route_create_params
        route_params[:owner] = User.current_user.userid if User.current_user.role == 'member'
        Route.transaction do
          @route = Route.create!(route_params)

          if @route.healthcheck_enabled
            @route.create_healthcheck!(healthcheck_params.permit(:path, :scheme, :hostname, :port, :interval, :timeout, :method,
                                                                 :follow_redirects, headers: {}))
          end

          name = RoutesService.generate_name
          if services.count == 1
            RoutesService.create!(
              route: @route,
              service: Service.filtered.find_by(id: services.first['id']),
              balance_type: :loadbalancer,
              value: nil,
              name: RoutesService.unique_name(name)
            )

          elsif services.count > 1
            services.each do |data|
              RoutesService.create!(
                route: @route,
                service: Service.filtered.find_by(id: data['id']),
                balance_type: :weighted,
                value: data['weight'],
                name: RoutesService.unique_name(name)
              )
            end
          end
        end
        render json: @route, status: :created
      end

      def update
        set_error_code('027')
        services = @route_params.delete(:services)
        Route.transaction do
          update_certificate
          @route.update(sanitize_params, services)
          if @route.healthcheck_enabled
            if @route.healthcheck
              @route.healthcheck.update!(healthcheck_params)
            else
              @route.create_healthcheck!(healthcheck_params)
            end
          else
            @route.healthcheck&.destroy!
          end
        end
        render json: @route.reload, status: :ok
      end

      def destroy
        set_error_code('028')
        @route.destroy!
        render json: nil, status: :no_content
      end

      private

      def set_route
        set_error_code('029')
        @route = Route.filtered.find(params[:id])
      end

      def check_params
        @route_params = params[:route]
        return render json: @route unless @route_params

        cloud_gateway_id = @route_params[:cloud_gateway_id]
        CloudGateway.filtered.find(cloud_gateway_id) if cloud_gateway_id
      end

      def update_certificate
        set_error_code('030')
        certificate_id = @route_params[:certificate_id]
        if certificate_id
          @route.update!(certificate_id:) if Certificate.filtered.find_by(id: certificate_id)
        else
          @route.update!(certificate_id: nil)
        end
      end

      def sanitize_params
        params.require(:route).permit(params_white_list)
      end

      def params_white_list
        %w[name hostname path target_port insecure tls_termination labels cloud_gateway_id owner source_proto
           destination_proto ip_version healthcheck_enabled]
      end

      def healthcheck_params
        healthcheck_params = @route_params.delete(:healthcheck)
        healthcheck_params.permit(:path, :scheme, :hostname, :port, :interval, :timeout, :method, :follow_redirects,
                                  headers: {})
      end

      def route_create_params
        params.require(:route).permit(:name, :hostname, :path, :target_port, :insecure, :tls_termination, :labels,
                                      :cloud_gateway_id, :owner, :source_proto, :destination_proto, :ip_version,
                                      :certificate_id, :healthcheck_enabled)
      end
    end
  end
end
