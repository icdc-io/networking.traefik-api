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

  def create_cloudgw
    CloudGateway.create!(params.require(:cloudgw).permit(:name, :account, :uuid))
  end

  def update_cloudgw
    @gateway = CloudGateway.find_by(:id => params[:id])
    if @gateway
      @gateway.update!(params.permit(:name, :account))
      render json: @gateway, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def delete_cloudgw
    @gateway.find_by(:id => params[:id])
    if @gateway
      @gateway.routes.each(&:destroy!)
      Certificate.where(:account => @gateway.account).each do |certificate|
        name = certificate.name
        certificate.destroy!
        Api::V1::CertificatesController.new.send(:remove_dir, "certificates/#{params[:uuid]}/#{name}")
      end
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


