module Api
  module V1
    class CertificatesController < ApplicationController
      skip_before_action :authorize, :authorize_action, only: %i[download]
      before_action :validate_certificate, only: %i[create update]
      before_action :set_certificate, only: %i[show update delete]
      before_action :check_cloud_gateway, only: %i[download]

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
        certificate_params =
          params.expect(certificate: %w[cert key ca dest_ca owner name])
        certificate = Certificate.store(certificate_params)
        render json: certificate, status: :created
      end

      def update
        set_error_code("011")
        if params["certificate"]
          @certificate.update_content(
            params.expect(certificate: %w[cert key ca dest_ca owner name])
          )
        end
        render json: @certificate, status: :ok
      end

      def delete
        set_error_code("012")
        @certificate.destroy!
      end

      def download
        set_error_code("013")
        file_path = File.join(
          ENV.fetch("USERS_CERT_PATH_ARCH", "certificates/download"),
          "#{params[:cloudgw_id]}.zip"
        )
        return send_file file_path if File.exist?(file_path)

        message = I18n.t("controllers.api.v1.certificates.download.file_not_found")
        render_not_found_response(message:, code: "ENT035", data: { message: })
      end

      private

      def validate_certificate
        set_error_code("014")
        cert_params = params.expect(certificate: %w[cert key])
        OpenSSL::X509::Certificate.new(cert_params["cert"])
        # maybe can fail in case of passphrase
        raise unless OpenSSL::PKey::RSA.new(cert_params["key"]).private?
      end

      def set_certificate
        set_error_code("015")
        @certificate = Certificate.filtered.find(params[:id])
      end

      def check_cloud_gateway
        cloudgw_id = params[:cloudgw_id]
        return unless cloudgw_id && !CloudGateway.exists?(cloudgw_id:)

        message = I18n.t("errors.cloud_gateway.record_not_found")
        render_not_found_response(message:, code: "ENT031", data: { message: })
      end
    end
  end
end
