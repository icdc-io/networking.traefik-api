class RenameUuidToCloudgwId < ActiveRecord::Migration[6.1]
  def change
    rename_column :cloud_gateways, :uuid, :cloudgw_id
  end
end
