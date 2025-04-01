# frozen_string_literal: true

module Api
  module V1
    class GatewaysController < ApplicationController
      before_action :set_gateway, only: %i[show update_cloudgw delete_cloudgw]

      def index
        render json: CloudGateway.filtered, status: :ok
      end

      def show
        render json: @gateway, status: :ok
      end

      def create_cloudgw
        @gateway = CloudGateway.new(params.permit(:name, :account, :cloudgw_id))
        unless @gateway.save
          return render_error_response(
            message: I18n.t('controllers.api.v1.gateways.create.creation_failed'),
            code: 'ENT009',
            errors: @gateway.errors.full_messages
          )
        end
        render json: @gateway, status: :created
      end

      def update_cloudgw
        unless @gateway.update(params.permit(:name, :account))
          return render_error_response(
            message: I18n.t('controllers.api.v1.gateways.update.updating_failed'),
            code: 'ENT010',
            errors: @gateway.errors.full_messages
          )
        end
        render json: @gateway, status: :ok
      end

      def delete_cloudgw
        @gateway.routes.each(&:destroy!)
        Certificate.where(account: @gateway.account).each do |certificate|
          name = certificate.name
          certificate.destroy!
        end
        @gateway.destroy!
        render json: nil, status: :no_content
      end

      def traefik_config
        if (gateway = CloudGateway.find_by(cloudgw_id: params[:cloudgw_id]))
          render json: gateway.config, content_type: 'text/yaml', status: :ok
        else
          render_not_found_response(message: I18n.t('controllers.api.v1.gateways.traefik_config.cloud_gateway_not_found'), code: 'ENT011', data: { message: I18n.t('controllers.api.v1.gateways.traefik_config.cloud_gateway_not_found') }) # TODO: leave 'data' for backward compatibility, remove it in future
        end
      end

      private

      def set_gateway
        @gateway = CloudGateway.filtered.find_by(id: params[:id])
        return if @gateway

        render_not_found_response(message: I18n.t('controllers.api.v1.gateways.set_gateway.not_found'), code: 'ENT012', data: { message: I18n.t('controllers.api.v1.gateways.set_gateway.not_found') }) # TODO: leave 'data' for backward compatibility, remove it in future
      end
    end
  end
end
