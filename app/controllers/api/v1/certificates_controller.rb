class Api::V1::CertificatesController < ApplicationController
  before_action :validate_certificate, only: [:create, :update]

  def index
    render json: Certificate.filtered, status: :ok
  end

  def show
    if @certificate = Certificate.filtered.find_by(:id => params[:id])
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
    if @certificate = Certificate.filtered.find_by(:id => params[:id])
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
    if @certificate = Certificate.filtered.find_by(:id => params[:id])
      raise "You can't delete certificate cause certificate don't have name" unless @certificate.name
      @certificate.destroy!
      render json: nil, status: :no_content
    else
      render json: nil, status: :not_found
    end
  end

  def download
    if @cloudgw = CloudGateway.find_by(:cloudgw_id => params[:cloudgw_id])
      send_file "#{ENV['USERS_CERT_PATH_ARCH']}/#{@cloudgw.cloudgw_id}.zip"
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
