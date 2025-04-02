class Api::V1::GatewaysController < ApplicationController
  before_action :set_gateway, only: %i[show update_cloudgw delete_cloudgw]

  def index
    render json: CloudGateway.filtered, status: :ok
  end

  def show
    render json: @gateway, status: :ok
  end

  def create_cloudgw
    @gateway = CloudGateway.create!(params.permit(:name, :account, :cloudgw_id))
    render json: @gateway, status: :created
  end

  def update_cloudgw
    @gateway.update!(params.permit(:name, :account))
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
    if gateway = CloudGateway.find_by(cloudgw_id: params[:cloudgw_id])
      render json: gateway.config, content_type: 'text/yaml', status: :ok
    else
      not_found("CloudGateway with id #{params[:cloudgw_id]}")
    end
  end

  private

  def set_gateway
    @gateway = CloudGateway.filtered.find_by(id: params[:id])
    not_found("CloudGateway with id #{params[:id]}") unless @gateway
  end
end
