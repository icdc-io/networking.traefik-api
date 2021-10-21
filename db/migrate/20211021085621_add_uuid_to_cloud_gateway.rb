class AddUuidToCloudGateway < ActiveRecord::Migration[6.1]
  def change
    add_column :cloud_gateways, :uuid, :string
  end
end
