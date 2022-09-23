class Certificate < ApplicationRecord
  has_many :routes
  attribute :values
  validates :name, uniqueness: {scope: :account}
  after_destroy :remove_cert_files
  after_create :prepare_to_downloading

  def self.store(params)
    path = "certificates/#{CloudGateway.find_by(:account => User.current_user.account.downcase).cloudgw_id}/#{params["name"]}"
    dir = find_or_build_path(path)
    cert = Certificate.new(:owner => params["owner"], :name => params["name"], :account => User.current_user.account)
    ["cert", "key", "ca", "dest_ca"].each do |file|
      File.write("#{dir}/#{file}", params[file])
      cert.send(:"#{file}_path=", "#{path}/#{file}")
    end
    cert.save!
    cert
  end

  def update_content(params)
    path = "certificates/#{CloudGateway.find_by(:account => User.current_user.account.downcase).cloudgw_id}/#{name}"
    dir = Certificate.find_or_build_path(path)
    
    ["cert", "key", "ca", "dest_ca"].each do |file|
      File.write("#{dir}/#{file}", params[file])
    end

    unless params["name"] == name
      update!(:name => params["name"])
      new_path = "certificates/#{CloudGateway.find_by(:account => User.current_user.account.downcase).cloudgw_id}/#{params["name"]}"
      FileUtils.mv(path, new_path)

      ["cert", "key", "ca", "dest_ca"].each do |file|
        send(:"#{file}_path=", "#{new_path}/#{file}")
        save!
      end

    end
    FileUtils.rm_rf( "tmp/certificates/#{CloudGateway.find_by(:account => account).cloudgw_id}/#{name}")
    prepare_to_downloading
    self    
  end

  def prepare_to_downloading
    CloudGateway.where(:account => User.current_user.account.downcase).each do |cloudgw|
      path = "tmp/certificates/#{cloudgw.cloudgw_id}"
      FileUtils.mkdir_p(path) unless Dir.exists?(path)
      FileUtils.cp_r("#{ENV['USERS_CERT_PATH']}/#{cloudgw.cloudgw_id}/#{name}", "#{path}/#{name}")
      input = File.open("#{path}/#{name}/ca")
      ca = input.read()
      output = File.open("#{path}/#{name}/cert", "a")
      output.write("\n#{ca}")
      output.close()
      input.close()
      recreate_tarball(cloudgw.cloudgw_id)
    end
  end

  private

  def self.find_or_build_path(path)
    start_path = Dir.pwd
    parts = path.split('/').compact
    parts.each do |directory|
      Dir.mkdir(directory) unless Dir.exists?(directory)
      Dir.chdir(directory)
    end
    final_path = Dir.pwd
    Dir.chdir(start_path)
    final_path
  end

  def values
    cert = OpenSSL::X509::Certificate.new(File.read(cert_path))
    certprops = OpenSSL::X509::Name.new(cert.issuer).to_a
    common_name = certprops.find {|name, _, _| name == "CN"}[1]
    organization = certprops.find {|name, _, _| name == "O"}[1]
    hostname = routes.collect(&:hostname).uniq
    {
      :cert => File.read(cert_path),
      :key => File.read(key_path),
      :ca => File.read(ca_path),
      :dest_ca => File.read(dest_ca_path),
      :hostnames => hostname,
      :valid_from => cert.not_before,
      :valid_until => cert.not_after,
      :issuer => "#{common_name} / #{organization}"
    }
  rescue => e
    {
      :cert => File.read(cert_path),
      :key => File.read(key_path),
      :ca => File.read(ca_path),
      :dest_ca => File.read(dest_ca_path)
    }
  end

  def remove_cert_files
    FileUtils.rm_rf( "#{ENV['USERS_CERT_PATH']}/#{CloudGateway.find_by(:account => account).cloudgw_id}/#{name}")
    FileUtils.rm_rf( "tmp/certificates/#{CloudGateway.find_by(:account => account).cloudgw_id}/#{name}")
  end

  def recreate_tarball(cloudgw_id)
    tarball = ZipFileGenerator.new("tmp/certificates/#{cloudgw_id}", "#{ENV['USERS_CERT_PATH_ARCH']}/#{cloudgw_id}.zip")
    tarball.write
  end
end
