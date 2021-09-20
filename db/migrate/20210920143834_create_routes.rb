class CreateRoutes < ActiveRecord::Migration[6.1]
  def change
    create_table :routes do |t|
      t.string :name
      t.string :hostname
      t.string :path
      t.numeric :target_port
      t.string :insecure
      t.string :tls_termination
      t.jsonb :labels
      t.references :cloud_gateway, null: false, foreign_key: true
      t.references :certificate, null: false, foreign_key: true

      t.timestamps
    end
  end
end
