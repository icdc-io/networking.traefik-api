class CreateRoutes < ActiveRecord::Migration[6.1]
  def change
    create_table :routes do |t|
      t.string :name
      t.string :hostname
      t.string :path
      t.numeric :target
      t.string :insecure
      t.numeric :tls
      t.string :labels
      t.references :gateways, null: false, foreign_key: true
      t.references :services, null: false, foreign_key: true
      t.references :certificate, null: false, foreign_key: true

      t.timestamps
    end
  end
end
