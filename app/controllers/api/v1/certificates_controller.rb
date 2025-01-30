class Api::V1::CertificatesController < ApplicationController
  before_action :validate_certificate, only: %i[create update]
  before_action :set_certificate, only: %i[show update delete]

  def index
    render json: Certificate.filtered.includes(:routes), status: :ok
  end

  def show
    render json: @certificate, status: :ok
  end

  def create
    certificate_params = params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name')
    certificate = Certificate.store(certificate_params)
    render json: certificate, status: :created
  end

  def update
    if params['certificate']
      @certificate.update_content(
        params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name')
      )
    end
    render json: @certificate, status: :ok
  end

  def delete
    raise "You can't delete certificate cause certificate don't have name" unless @certificate.name

    @certificate.destroy!
    render json: nil, status: :no_content
  end

  def download
    if @cloudgw = CloudGateway.find_by(cloudgw_id: params[:cloudgw_id])
      send_file File.join(ENV.fetch('USERS_CERT_PATH_ARCH'), "#{@cloudgw.cloudgw_id}.zip")
    else
      not_found("CloudGateway with id #{params[:cloudgw_id]}")
    end
  end

  private

  def validate_certificate
    cert_params = params.require('certificate').permit('cert', 'key')
    OpenSSL::X509::Certificate.new(cert_params['cert'])
    raise unless OpenSSL::PKey::RSA.new(cert_params['key']).private? # maybe can fail in case of passphrase
  rescue StandardError
    abort('Invalid certificate')
  end

  def set_certificate
    @certificate = Certificate.filtered.find_by(id: params[:id])
    not_found("Certificate with id #{params[:id]}") unless @certificate
  end
end
