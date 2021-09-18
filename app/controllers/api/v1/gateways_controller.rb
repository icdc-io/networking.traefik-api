class Api::V1::GatewaysController < ApplicationController

  def index
    @gateways = Gateway.all
    render json: @gateways, status: :ok
  end

  def show
    @gateway = Gateway.find_by(:id => params[:id])
    if @gateway
      render json: @gateway, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    params.require(:cloudgw).permit(:name, :account)
    Gateway.create!(params[:cloudgw])
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
end
