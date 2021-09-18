class Api::V1::GatewaysController < ApplicationController

  def index
    @gateways = Gateway.all
    render json: @gateways, status: :ok
  end
end
