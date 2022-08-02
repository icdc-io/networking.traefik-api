class Api::V1::GatewaysController < ApplicationController

  def index
    render json: CloudGateway.filtered, status: :ok
  end

  def show
    if @gateway = CloudGateway.filtered.find_by(:id => params[:id])
      render json: @gateway, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create_cloudgw
    @gateway = CloudGateway.create!(params.permit(:name, :account, :cloudgw_id))
    render json: @gateway, status: :created
  end

  def update_cloudgw
    @gateway = CloudGateway.filtered.find_by(:id => params[:id])
    if @gateway
      @gateway.update!(params.permit(:name, :account))
      render json: @gateway, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def delete_cloudgw
    @gateway = CloudGateway.filtered.find_by(:id => params[:id])
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
    if gateway = CloudGateway.find_by(:cloudgw_id => params[:cloudgw_id])
      render :json => gateway.config, :content_type => 'text/yaml', :status => :ok
    else
      render :json => nil, :status => :not_found
    end
  end
end
