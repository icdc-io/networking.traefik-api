class AddFieldsToRoute < ActiveRecord::Migration[6.1]
  def change
    add_column :routes, :source_proto, :string
    add_column :routes, :destination_proto, :string
    add_column :routes, :ip_version, :string
  end
end
