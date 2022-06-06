class Api::V1::CertificatesController < ApplicationController
  before_action :validate_certificate, only: [:create, :update]

  def index
    if $location_admin
      @certificates = Certificate.all
    elsif $account_admin
      @certificates = Certificate.where(:account => $current_account)
    else
      @certificates = Certificate.where(:account => $current_account, :owner => @@email)
    end
    render json: @certificates, status: :ok
  end

  def show
    if @certificate = Certificate.find_by(:id => params[:id])
      if $location_admin ||
          (@certificate.account == $current_account && ($account_admin || @certificate.owner == @@email))
        return render json: @certificate, status: :ok
      end
    end
      render json: nil, status: :not_found
  end

  def create
    certificate_params = params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name')
    certificate = Certificate.store(certificate_params)
    render json: certificate, status: :created
  end

  def update
    if @certificate = Certificate.find_by(:id => params[:id])
      if $location_admin ||
          (@certificate.account == $current_account && ($account_admin || @certificate.owner == @@email))
        if params['certificate']
        return render :json =>
          @certificate.update_content(
            params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name')
          ), status: :ok
        else
          return render :json => @certificate, status: :ok
        end
      end
    end
    render json: nil, status: :not_found
  end

  def delete
    if @certificate = Certificate.find_by(:id => params[:id])
      raise "You can't delete certificate cause certificate don't have name" unless @certificate.name
      if $location_admin ||                                                                                              
          (@certificate.account == $current_account && ($account_admin || @certificate.owner == @@email))
        account_uuid = CloudGateway.find_by(:account => $current_account).cloudgw_id
        @certificate.destroy!
        return render json: nil, status: :no_content
      end
    end
    render json: nil, status: :not_found
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
