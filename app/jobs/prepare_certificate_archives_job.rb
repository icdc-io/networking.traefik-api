# frozen_string_literal: true

class PrepareCertificateArchivesJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform(account)
    FileUtils.mkdir_p(ENV.fetch('USERS_CERT_PATH_ARCH'))
    FileUtils.mkdir_p("#{ENV.fetch('USERS_CERT_PATH')}/#{account}")

    Dir.mktmpdir do |dir|
      Certificate.where(account:).each { |certificate| copy_files(certificate, dir) }

      archive_path = "#{ENV.fetch('USERS_CERT_PATH')}/#{account}/archive.zip"
      ZipFileGenerator.new(dir, archive_path).write

      CloudGateway.where(account:).pluck(:cloudgw_id).each do |cloudgw_id|
        FileUtils.cp_r(archive_path, "#{ENV.fetch('USERS_CERT_PATH_ARCH')}/#{cloudgw_id}.zip")
      end

      FileUtils.rm_f(archive_path)
    end
  end

  private

  def copy_files(certificate, dir)
    FileUtils.mkdir_p("#{dir}/#{certificate.name}")
    FileUtils.cp_r(certificate.cert_path,    "#{dir}/#{certificate.name}")
    FileUtils.cp_r(certificate.key_path,     "#{dir}/#{certificate.name}")
    FileUtils.cp_r(certificate.ca_path,      "#{dir}/#{certificate.name}")
    FileUtils.cp_r(certificate.dest_ca_path, "#{dir}/#{certificate.name}")
    ca = File.read("#{dir}/#{certificate.name}/ca")
    File.write("#{dir}/#{certificate.name}/cert", "\n#{ca}", mode: 'a')
  end
end
