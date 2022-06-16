class Api::V1::CertificatesController < ApplicationController
  before_action :validate_certificate, only: [:create, :update]

  def index
    render json: Certificate.filtered_list, status: :ok
  end

  def show
    if @certificate = Certificate.find_by(:id => params[:id])&.rbac
      render json: @certificate, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    certificate_params = params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name')
    certificate = Certificate.store(certificate_params)
    render json: certificate, status: :created
  end

  def update
    if @certificate = Certificate.find_by(:id => params[:id])&.rbac
      if params['certificate']
        @certificate.update_content(
          params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name')
        )
      end
      render json: @certificate, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def delete
    if @certificate = Certificate.find_by(:id => params[:id])&.rbac
      raise "You can't delete certificate cause certificate don't have name" unless @certificate.name
      @certificate.destroy!
      render json: nil, status: :no_content
    else
      render json: nil, status: :not_found
    end
  end

  def download
    if @cloudgw = CloudGateway.find_by(:cloudgw_id => params[:cloudgw_id])
      cert_path = ENV['CERT_PATH'] || 'certificates'
      raise json: nil, status: :not_found unless Dir.exists?(cert_path)
      tarball = ZipFileGenerator.new("#{cert_path}/#{@cloudgw.cloudgw_id}", "tmp/#{cert_path}.zip")
      tarball.write
      send_file "tmp/#{cert_path}.zip"
    else
      render json: nil, status: :not_found
    end
  end

  def validate_certificate
    cert_params = params.require('certificate').permit('cert', 'key')
    OpenSSL::X509::Certificate.new(cert_params["cert"])
    raise unless OpenSSL::PKey::RSA.new(cert_params["key"]).private? # maybe can fail in case of passphrase
  rescue
    return abort("Invalid certificate")
  end

end
