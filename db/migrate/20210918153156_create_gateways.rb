class CreateGateways < ActiveRecord::Migration[6.1]
  def change
    create_table :gateways do |t|
      t.string :name
      t.string :account

      t.timestamps
    end
  end
end
