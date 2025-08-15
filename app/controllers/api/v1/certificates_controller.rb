module Api
  module V1
    class CertificatesController < ApplicationController
      before_action :validate_certificate, only: %i[create update]
      before_action :set_certificate, only: %i[show update delete]

      def index
        set_error_code("008")
        render json: Certificate.filtered.includes(:routes), status: :ok
      end

      def show
        set_error_code("009")
        render json: @certificate, status: :ok
      end

      def create
        set_error_code("010")
        certificate_params = params.require("certificate").permit("cert",
                                                                  "key", "ca", "dest_ca", "owner", "name")
        certificate = Certificate.store(certificate_params)
        render json: certificate, status: :created
      end

      def update
        set_error_code("011")
        if params["certificate"]
          @certificate.update_content(
            params.require("certificate").permit("cert", "key", "ca",
                                                 "dest_ca", "owner", "name")
          )
        end
        render json: @certificate, status: :ok
      end

      def delete
        set_error_code("012")
        @certificate.destroy!
        render json: nil, status: :no_content
      end

      def download
        set_error_code("013")
        @cloudgw = CloudGateway.find_by!(cloudgw_id: params[:cloudgw_id])
        send_file File.join(
          ENV.fetch("USERS_CERT_PATH_ARCH", "certificates/download"),
          "#{@cloudgw.cloudgw_id}.zip"
        )
      end

      private

      def validate_certificate
        set_error_code("014")
        cert_params = params.require("certificate").permit("cert", "key")
        OpenSSL::X509::Certificate.new(cert_params["cert"])
        # maybe can fail in case of passphrase
        raise unless OpenSSL::PKey::RSA.new(cert_params["key"]).private?
      end

      def set_certificate
        set_error_code("015")
        @certificate = Certificate.filtered.find(params[:id])
      end
    end
  end
end
