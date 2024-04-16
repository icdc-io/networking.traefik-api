namespace :certificates do
  desc "Task to change the beginning of cetrificate paths." \
  "Usage: certificates:change_paths OLD_PATH=certificates NEW_PATH=/cetrificates"
  task change_paths: [:environment] do |t, args|
    old_path = ENV['OLD_PATH']
    new_path = ENV['NEW_PATH']
    path_fields = %w[cert_path key_path ca_path dest_ca_path]

    puts "Finding certificates with path beginning with: #{old_path}"
    certificates = Certificate.where("cert_path ILIKE '#{old_path}%'")

    puts "Found #{certificates.count} certificates"

    unless certificates.empty?
      certificates.find_each do |certificate|
        path_fields.each do |field|
          certificate.send(:"#{field}=", certificate.send(field).gsub(/^#{old_path}/, new_path))
        end
        certificate.save!
      end

      puts "All certificate paths have been updated"
    end
  end
end