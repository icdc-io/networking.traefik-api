class CreateCertificates < ActiveRecord::Migration[6.1]
  def change
    create_table :certificates do |t|
      t.text :cert
      t.text :key
      t.text :ca
      t.text :dest_ca

      t.timestamps
    end
  end
end
