class Api::V1::GatewaysController < ApplicationController

  def index
    @gateways = CloudGateway.all
    render json: @gateways, status: :ok
  end

  def show
    @gateway = CloudGateway.find_by(:id => params[:id])
    if @gateway
      render json: @gateway, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    gw = CloudGateway.create!(params.require(:cloudgw).permit(:name, :account))
    gw.uuid = SecureRandom.hex
    gw.save!
  end

  def delete
    @gateway.find_by(:id => params[:id])
    if @gateway
      @gateway.destroy!
      render json: @gateway, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def traefik_config
    config = CloudGateway.find_by(:uuid => params[:uuid])&.config
    render :json => config, :content_type => 'text/yaml'
  end
end


