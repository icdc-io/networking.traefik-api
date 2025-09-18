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

      archive_path = File.join(
        ENV.fetch("USERS_CERT_PATH", "certificates"),
        account,
        "archive.zip"
      )
      ZipFileGenerator.new(dir, archive_path).write

      CloudGateway.where(account:).pluck(:cloudgw_id).each do |cloudgw_id|
        file_path = File.join(
          ENV.fetch("USERS_CERT_PATH_ARCH", "certificates/download"),
          "#{cloudgw_id}.zip"
        )
        FileUtils.cp_r(archive_path, file_path)
      end

      FileUtils.rm_f(archive_path)
    end
  end

  private

  # TODO: Move this to Certificate class
  def copy_files(certificate, dir)
    path = File.join(dir, certificate.name)
    FileUtils.mkdir_p(path)

    copy_file(certificate.cert_path, path)
    copy_file(certificate.key_path, path)
    copy_file(certificate.ca_path, path)
    copy_file(certificate.dest_ca_path, path)

    ca = File.read("#{path}/ca")
    File.write("#{path}/cert", "\n#{ca}", mode: "a")
  end

  def copy_file(file_path, dest_path)
    FileUtils.cp_r(
      File.join(ENV.fetch("USERS_CERT_PATH", "certificates"), file_path),
      dest_path
    )
  end
end
