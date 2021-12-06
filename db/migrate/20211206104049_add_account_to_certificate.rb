class AddAccountToCertificate < ActiveRecord::Migration[6.1]
  def change
    add_column :certificates, :account, :string
  end
end
