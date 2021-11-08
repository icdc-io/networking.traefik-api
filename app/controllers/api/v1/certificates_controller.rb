class Api::V1::CertificatesController < ApplicationController

  def index
    puts @@user_email
    @certificates = Certificate.all.select { |cert| cert.owner.eql?(@@user_email) }
    render json: @certificates, status: :ok
  end

  def show
    @certificate = Certificate.find_by(:id => params[:id])
    if @certificate&.owner.eql?(@@user_email)
      render json: @certificate, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    certificate = Certificate.store(params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name'))
    render json: certificate, status: :created
  end

  def delete
    @certificate.find_by(:id => params[:id])
    if @certificate&.owner.eql?(@@user_email)
      @certificate.destroy!
      render json: @certificate, status: :ok
    else
      render json: nil, status: :not_found
    end
  end
end