# frozen_string_literal: true

module Api
  module V1
    class GatewaysController < ApplicationController
      before_action :set_gateway, only: %i[show update_cloudgw delete_cloudgw]

      def index
        set_error_code('016')
        render json: CloudGateway.filtered, status: :ok
      end

      def show
        set_error_code('017')
        render json: @gateway, status: :ok
      end

      def create_cloudgw
        set_error_code('018')
        @gateway = CloudGateway.create!(params.permit(:name, :account, :cloudgw_id))
        render json: @gateway, status: :created
      end

      def update_cloudgw
        set_error_code('019')
        @gateway.update!(params.permit(:name, :account))
        render json: @gateway, status: :ok
      end

      def delete_cloudgw
        set_error_code('020')
        @gateway.routes.each(&:destroy!)
        Certificate.where(account: @gateway.account).each do |certificate|
          name = certificate.name
          certificate.destroy!
        end
        @gateway.destroy!
        render json: nil, status: :no_content
      end

      def traefik_config
        set_error_code('021')
        gateway = CloudGateway.find_by!(cloudgw_id: params[:cloudgw_id])
        render json: gateway.config, content_type: 'text/yaml', status: :ok
      end

      private

      def set_gateway
        set_error_code('022')
        @gateway = CloudGateway.filtered.find(params[:id])
      end
    end
  end
end
