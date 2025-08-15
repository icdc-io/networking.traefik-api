class PrepareCertificateArchivesJob
  include Sidekiq::Job

  sidekiq_options retry: false

  def perform(account)
    FileUtils.mkdir_p(ENV.fetch("USERS_CERT_PATH_ARCH",
                                "certificates/download"))
    FileUtils.mkdir_p(File.join(
                        ENV.fetch("USERS_CERT_PATH",
                                  "certificates"), account
                      ))

    Dir.mktmpdir do |dir|
      Certificate.where(account:).find_each do |certificate|
        copy_files(certificate, dir)
      end

      archive_path = File.join(ENV.fetch("USERS_CERT_PATH", "certificates"), account,
                               "archive.zip")
      ZipFileGenerator.new(dir, archive_path).write

      CloudGateway.where(account:).pluck(:cloudgw_id).each do |cloudgw_id|
        FileUtils.cp_r(archive_path,
                       File.join(ENV.fetch("USERS_CERT_PATH_ARCH", "certificates/download"),
                                 "#{cloudgw_id}.zip"))
      end

      FileUtils.rm_f(archive_path)
    end
  end

  private

  def copy_files(certificate, dir)
    path = File.join(dir, certificate.name)
    FileUtils.mkdir_p(path)
    FileUtils.cp_r(
      File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                certificate.cert_path),    path
    )
    FileUtils.cp_r(
      File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                certificate.key_path),     path
    )
    FileUtils.cp_r(
      File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                certificate.ca_path),      path
    )
    FileUtils.cp_r(
      File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                certificate.dest_ca_path), path
    )
    ca = File.read("#{path}/ca")
    File.write("#{path}/cert", "\n#{ca}", mode: "a")
  end
end
