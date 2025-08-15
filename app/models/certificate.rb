class Certificate < ApplicationRecord
  attribute :values

  has_many :routes

  validates :name, uniqueness: { scope: :account }

  after_destroy :remove_cert_files

  def self.store(params)
    cert = Certificate.new(params.slice("name",
                                        "owner").merge("account" => User.current_user.account))
    cert.write_files(params.slice("cert", "key", "ca", "dest_ca"))
    cert.save!
    PrepareCertificateArchivesJob.perform_async(cert.account)
    cert
  end

  def update_content(params)
    write_files(params.slice("cert", "key", "ca", "dest_ca"))

    if params["name"] && params["name"] != name
      old_path = path
      @path = nil
      @full_path = nil

      self.name = params["name"]
      FileUtils.mkdir_p(full_path)

      %w[cert key ca dest_ca].each do |file|
        FileUtils.mv(
          File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                    send(:"#{file}_path")), "#{full_path}/#{file}"
        )
        send(:"#{file}_path=", "#{path}/#{file}")
      end

      FileUtils.rm_f(File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                               old_path))
    end

    save!
    PrepareCertificateArchivesJob.perform_async(account)
    self
  end

  def full_path
    @full_path ||= File.join(ENV.fetch("USERS_CERT_PATH", "certificates"), path)
  end

  def path
    @path ||= File.join(account, name)
  end

  def write_files(files_hash)
    FileUtils.mkdir_p(full_path)

    files_hash.each do |file, value|
      File.write("#{full_path}/#{file}", value)
      send(:"#{file}_path=", "#{path}/#{file}")
    end
  end

  private

  def values
    cert = OpenSSL::X509::Certificate.new(File.read(File.join(
                                                      ENV.fetch(
                                                        "USERS_CERT_PATH", "certificates"
                                                      ), cert_path
                                                    )))
    certprops = OpenSSL::X509::Name.new(cert.issuer).to_a
    common_name = certprops.find { |name, _, _| name == "CN" }[1]
    organization = certprops.find { |name, _, _| name == "O" }[1]
    hostname = routes.collect(&:hostname).uniq
    {
      cert:        File.read(File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                                       cert_path)),
      key:         File.read(File.join(
                               ENV.fetch("USERS_CERT_PATH",
                                         "certificates"), key_path
                             )),
      ca:          File.read(File.join(
                               ENV.fetch("USERS_CERT_PATH",
                                         "certificates"), ca_path
                             )),
      dest_ca:     File.read(File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                                       dest_ca_path)),
      hostnames:   hostname,
      valid_from:  cert.not_before,
      valid_until: cert.not_after,
      issuer:      "#{common_name} / #{organization}"
    }
  rescue
    {
      cert:    File.read(File.join(
                           ENV.fetch("USERS_CERT_PATH",
                                     "certificates"), cert_path
                         )),
      key:     File.read(File.join(
                           ENV.fetch("USERS_CERT_PATH",
                                     "certificates"), key_path
                         )),
      ca:      File.read(File.join(
                           ENV.fetch("USERS_CERT_PATH", "certificates"), ca_path
                         )),
      dest_ca: File.read(File.join(
                           ENV.fetch("USERS_CERT_PATH",
                                     "certificates"), dest_ca_path
                         ))
    }
  end

  def remove_cert_files
    FileUtils.rm_rf(full_path)

    # TODO: Remove lines below
    cloudgw_id = CloudGateway.find_by(account:).cloudgw_id
    FileUtils.rm_rf(File.join(ENV.fetch("USERS_CERT_PATH", "certificates"),
                              cloudgw_id, name))
    FileUtils.rm_rf("certificates/#{cloudgw_id}/#{name}")
    FileUtils.rm_rf("tmp/certificates/#{cloudgw_id}/#{name}")
  end
end
