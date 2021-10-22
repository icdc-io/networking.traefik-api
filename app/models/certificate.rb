class Certificate < ApplicationRecord
  has_many :routes

  def self.store(params)
    # ahrechushkin: So, when we create certificate separately from route
    # we don't knows name of route, i wanna to divide certs by folders
    # and i'll generate folder name
    path = "certificates/#{CloudGateway.find_by(:account => $current_account.downcase).uuid}/#{params["name"]}"
    dir = find_or_build_path(path)
    cert = Certificate.new(:owner_email => params["owner_email"])
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
end
