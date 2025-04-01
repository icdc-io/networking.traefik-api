# frozen_string_literal: true

module Api
  module V1
    class CertificatesController < ApplicationController
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
      rescue ActiveRecord::RecordInvalid => e
        render_error_response(
          message: I18n.t('controllers.api.v1.certificates.create.creation_failed'),
          code: 'ENT003',
          errors: [e]
        )
      end

      def update
        if params['certificate']
          @certificate.update_content(
            params.require('certificate').permit('cert', 'key', 'ca', 'dest_ca', 'owner', 'name')
          )
        end
        render json: @certificate, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        render_error_response(
          message: I18n.t('controllers.api.v1.certificates.update.updating_failed'),
          code: 'ENT004',
          errors: [e]
        )
      end

      def delete
        unless @certificate.name
          return render_error_response(
            message: I18n.t('controllers.api.v1.certificates.delete.destroying_failed'),
            status: 400,
            code: 'ENT005',
            errors: ["You can't delete certificate cause certificate don't have name"]
          )
        end

        @certificate.destroy!
        render json: nil, status: :no_content
      end

      def download
        if (@cloudgw = CloudGateway.find_by(cloudgw_id: params[:cloudgw_id]))
          send_file File.join(ENV.fetch('USERS_CERT_PATH_ARCH'), "#{@cloudgw.cloudgw_id}.zip")
        else
          render_not_found_response(message: I18n.t('controllers.api.v1.certificates.download.cloud_gateway_not_found'), code: 'ENT006', data: { message: I18n.t('controllers.api.v1.certificates.download.cloud_gateway_not_found') }) # TODO: leave 'data' for backward compatibility, remove it in future
        end
      end

      private

      def validate_certificate
        cert_params = params.require('certificate').permit('cert', 'key')
        OpenSSL::X509::Certificate.new(cert_params['cert'])
        raise unless OpenSSL::PKey::RSA.new(cert_params['key']).private? # maybe can fail in case of passphrase
      rescue StandardError => e
        status = ActionDispatch::ExceptionWrapper.status_code_for_exception(e.class.name)
        render_error_response(message: I18n.t('controllers.api.v1.certificates.validate_certificate.invalid_certificate'), status:, code: 'ENT007', errors: [e], data: { message: I18n.t('controllers.api.v1.certificates.validate_certificate.invalid_certificate') }) # TODO: leave 'data' for backward compatibility, remove it in future
      end

      def set_certificate
        @certificate = Certificate.filtered.find_by(id: params[:id])
        return if @certificate

        render_not_found_response(message: I18n.t('controllers.api.v1.certificates.set_certificate.not_found'), code: 'ENT008', data: { message: I18n.t('controllers.api.v1.certificates.set_certificate.not_found') }) # TODO: leave 'data' for backward compatibility, remove it in future
      end
    end
  end
end
