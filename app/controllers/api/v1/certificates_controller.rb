class Api::V1::CertificatesController < ApplicationController

  def index
    @certificates = Certificate.all.select { |certif| certif.owner_email.eql?(@@user_email) }
    render json: @certificates, status: :ok
  end

  def show
    @certificate = Certificate.find_by(:id => params[:id])
    if @certificate&.owner_email.eql?(@@user_email)
      render json: @certificate, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    Certificate.create!(params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner_email'))
  end

  def delete
    @certificate.find_by(:id => params[:id])
    if @certificate&.owner_email.eql?(@@user_email)
      @certificate.destroy!
      render json: @certificate, status: :ok
    else
      render json: nil, status: :not_found
    end
  end
end
