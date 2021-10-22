class AddNameToCertificate < ActiveRecord::Migration[6.1]
  def change
    add_column :certificates, :name, :string
    rename_column :certificates, :ca, :ca_path
    rename_column :certificates, :key, :key_path
    rename_column :certificates, :cert, :cert_path
    rename_column :certificates, :dest_ca, :dest_ca_path
  end
end
