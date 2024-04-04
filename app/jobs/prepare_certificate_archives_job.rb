# frozen_string_literal: true

class PrepareCertificateArchivesJob
  include Sidekiq::Job
  sidekiq_options retry: false

  def perform(account)
    FileUtils.mkdir_p(File.join(Rails.root, ENV.fetch('USERS_CERT_PATH_ARCH')))
    FileUtils.mkdir_p(File.join(Rails.root, ENV.fetch('USERS_CERT_PATH'), account))

    Dir.mktmpdir do |dir|
      Certificate.where(account:).each { |certificate| copy_files(certificate, dir) }

      archive_path = File.join(Rails.root, ENV.fetch('USERS_CERT_PATH'), account, "archive.zip")
      ZipFileGenerator.new(dir, archive_path).write

      CloudGateway.where(account:).pluck(:cloudgw_id).each do |cloudgw_id|
        FileUtils.cp_r(archive_path, File.join(Rails.root, ENV.fetch('USERS_CERT_PATH_ARCH'), "#{cloudgw_id}.zip"))
      end

      FileUtils.rm_f(archive_path)
    end
  end

  private

  def copy_files(certificate, dir)
    path = File.join(Rails.root, dir, certificate.name)
    FileUtils.mkdir_p(path)
    FileUtils.cp_r(File.join(Rails.root, certificate.cert_path),    path)
    FileUtils.cp_r(File.join(Rails.root, certificate.key_path),     path)
    FileUtils.cp_r(File.join(Rails.root, certificate.ca_path),      path)
    FileUtils.cp_r(File.join(Rails.root, certificate.dest_ca_path), path)
    ca = File.read("#{path}/ca")
    File.write("#{path}/cert", "\n#{ca}", mode: 'a')
  end
end
