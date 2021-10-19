class UpdateCertificates < ActiveRecord::Migration[6.1]
  def change
    add_column :certificates, :owner_email, :string
  end
end
