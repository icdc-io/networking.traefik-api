class Api::V1::CertificatesController < ApplicationController

  def index
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

  def download
    @cloudgw = CloudGateway.find_by(:uuid => params[:uuid])
    if @cloudgw
      cert_path = ENV['CERT_PATH'] || 'certificates'
      raise json: nil, status: :not_found unless Dir.exists?(cert_path)
      tarball = ZipFileGenerator.new("#{cert_path}/#{@cloudgw.uuid}", "tmp/#{cert_path}.zip")
      tarball.write
      send_file "tmp/#{cert_path}.zip"
    else
      render json: nil, status: :not_found
    end
  end

end