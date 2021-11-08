class Certificate < ApplicationRecord
  has_many :routes
  attribute :values

  def self.store(params)
    path = "certificates/#{CloudGateway.find_by(:account => $current_account.downcase).uuid}/#{params["name"]}"
    dir = find_or_build_path(path)
    cert = Certificate.new(:owner => params["owner"], :name => params["name"])
    ["cert", "key", "ca", "dest_ca"].each do |file|
      File.write("#{dir}/#{file}", params[file])
      cert.send(:"#{file}_path=", "#{path}/#{file}")
    end
    cert.save!
    cert
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
    {
      :cert => File.read(cert_path),
      :key => File.read(key_path),
      :ca => File.read(ca_path),
      :dest_ca => File.read(dest_ca_path)
    }
  end
end
