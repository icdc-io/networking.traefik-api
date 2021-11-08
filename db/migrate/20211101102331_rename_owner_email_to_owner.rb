class RenameOwnerEmailToOwner < ActiveRecord::Migration[6.1]
  def change
    rename_column :certificates, :owner_email, :owner
    rename_column :routes, :owner_email, :owner
  end
end
