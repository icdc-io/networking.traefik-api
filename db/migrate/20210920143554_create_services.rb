class CreateServices < ActiveRecord::Migration[6.1]
  def change
    create_table :services do |t|
      t.string :name
      t.bigint :ext_id
      t.string :ipaddresses
      t.string :owner
      t.string :account
      t.timestamps
    end
  end
end
