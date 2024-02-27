# frozen_string_literal: true

class Certificate < ApplicationRecord
  attribute :values

  has_many :routes

  validates :name, uniqueness: { scope: :account }

  after_destroy :remove_cert_files

  def self.store(params)
    cert = Certificate.new(params.slice('name', 'owner').merge('account' => User.current_user.account))
    cert.write_files(params.slice('cert', 'key', 'ca', 'dest_ca'))
    cert.save!
    PrepareCertificateArchivesJob.perform_async(cert.account)
    cert
  end

  def update_content(params)
    write_files(params.slice('cert', 'key', 'ca', 'dest_ca'))

    if params['name'] && params['name'] != name
      old_path = path
      @path = nil
      self.name = params['name']
      FileUtils.mkdir_p(path)

      %w[cert key ca dest_ca].each do |file|
        FileUtils.mv(send(:"#{file}_path"), "#{path}/#{file}")
        send(:"#{file}_path=", "#{path}/#{file}")
      end

      FileUtils.rm_f(old_path)
    end

    save!
    PrepareCertificateArchivesJob.perform_async(account)
    self
  end

  def path
    @path ||= "#{ENV.fetch('USERS_CERT_PATH')}/#{account}/#{name}"
  end

  def write_files(files_hash)
    FileUtils.mkdir_p(path)

    files_hash.each do |file, value|
      File.write("#{path}/#{file}", value)
      send(:"#{file}_path=", "#{path}/#{file}")
    end
  end

  private

  def values
    cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
    certprops = OpenSSL::X509::Name.new(cert.issuer).to_a
    common_name = certprops.find { |name, _, _| name == 'CN' }[1]
    organization = certprops.find { |name, _, _| name == 'O' }[1]
    hostname = routes.collect(&:hostname).uniq
    {
      cert: File.read(cert_path),
      key: File.read(key_path),
      ca: File.read(ca_path),
      dest_ca: File.read(dest_ca_path),
      hostnames: hostname,
      valid_from: cert.not_before,
      valid_until: cert.not_after,
      issuer: "#{common_name} / #{organization}"
    }
  rescue StandardError
    {
      cert: File.read(cert_path),
      key: File.read(key_path),
      ca: File.read(ca_path),
      dest_ca: File.read(dest_ca_path)
    }
  end

  def remove_cert_files
    FileUtils.rm_rf("#{ENV.fetch('USERS_CERT_PATH', nil)}/#{account}/#{name}")

    cloudgw_id = CloudGateway.find_by(account:).cloudgw_id
    FileUtils.rm_rf("#{ENV.fetch('USERS_CERT_PATH', nil)}/#{cloudgw_id}/#{name}")
    FileUtils.rm_rf("certificates/#{cloudgw_id}/#{name}")
    FileUtils.rm_rf("tmp/certificates/#{cloudgw_id}/#{name}")
  end

  def recreate_tarball(cloudgw_id)
    tarball = ZipFileGenerator.new("tmp/certificates/#{cloudgw_id}",
                                   "#{ENV.fetch('USERS_CERT_PATH_ARCH', nil)}/#{cloudgw_id}.zip")
    tarball.write
  end
end
