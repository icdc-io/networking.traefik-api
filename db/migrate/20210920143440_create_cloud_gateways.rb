class CreateCloudGateways < ActiveRecord::Migration[6.1]
  def change
    create_table :cloud_gateways do |t|
      t.string :name
      t.string :account

      t.timestamps
    end
  end
end
