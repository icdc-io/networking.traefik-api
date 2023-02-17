class CreateHealthchecks < ActiveRecord::Migration[6.1]
  def change
    create_table :healthchecks do |t|
      t.string :path, default: '/'
      t.string :scheme
      t.integer :port
      t.integer :interval, default: 30
      t.string :hostname
      t.jsonb :headers
      t.string :method, default: 'GET'
      t.boolean :follow_redirects, default: true

      t.timestamps
    end
  end
end
