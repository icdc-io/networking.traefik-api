class Api::V1::GatewaysController < ApplicationController

  def index
    if $location_admin
      @gateways = CloudGateway.all
    else
      @gateways = CloudGateway.where(:account => $current_account)
    end
    render json: @gateways, status: :ok
  end

  def show
    @gateway = CloudGateway.find_by(:id => params[:id])
    if @gateway && ( $location_admin || @gateway.account == $current_account )
      render json: @gateway, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create_cloudgw
    @gateway = CloudGateway.create!(params.permit(:name, :account, :cloudgw_id))
    render json: @gateway, status: :ok
  end

  def update_cloudgw
    @gateway = CloudGateway.find_by(:id => params[:id])
    if @gateway
      @gateway.update!(params.permit(:name, :account))
      render json: @gateway, status: :created
    else
      render json: nil, status: :not_found
    end
  end

  def delete_cloudgw
    @gateway = CloudGateway.find_by(:id => params[:id])
    if @gateway
      @gateway.routes.each(&:destroy!)
      Certificate.where(:account => @gateway.account).each do |certificate|
        name = certificate.name
        certificate.destroy!
        Api::V1::CertificatesController.new.send(:remove_dir, "certificates/#{@gateway.cloudgw_id}/#{name}")
      end
      @gateway.destroy!
      render json: nil, status: :no_content
    else
      render json: nil, status: :not_found
    end
  end

  def traefik_config
    config = CloudGateway.find_by(:cloudgw_id => params[:cloudgw_id])&.config
    render :json => config, :content_type => 'text/yaml', :status => :ok
  end
end
