class Api::V1::CertificatesController < ApplicationController

  def index
    @certificates = Certificate.all.select { |cert| cert.owner.eql?(@@email) || $location_admin }
    render json: @certificates, status: :ok
  end

  def show
    @certificate = Certificate.find_by(:id => params[:id])
    if @certificate&.owner.eql?(@@email) || $location_admin
      render json: @certificate, status: :ok
    else
      render json: nil, status: :not_found
    end
  end

  def create
    certificate = Certificate.store(params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name'))
    render json: certificate, status: :created
  end

  def update
    @certificate = Certificate.find_by(:id => params[:id])
    if @certificate&.owner.eql?(@@email) || $location_admin
      render :json =>
        @certificate.update_content(params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name')),
        status: :ok
    end
  end

  def delete
    @certificate = Certificate.find_by(:id => params[:id])
    raise "You can't delete certificate cause certificate don't have name" unless @certificate.name
    if @certificate&.owner.eql?(@@email) || $location_admin
      account_uuid = CloudGateway.find_by(:account => $current_account).uuid
      @certificate.destroy!
      remove_dir("certificates/#{account_uuid}/#{@certificate.name}")
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

  private

  def remove_dir(path)
    if File.directory?(path)
      Dir.foreach(path) do |file|
        if ((file.to_s != ".") and (file.to_s != ".."))
          remove_dir("#{path}/#{file}")
        end
      end
      Dir.delete(path)
    else
      File.delete(path)
    end
  end

end