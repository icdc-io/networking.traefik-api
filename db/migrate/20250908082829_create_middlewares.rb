class CreateMiddlewares < ActiveRecord::Migration[8.0]
  def change
    create_table :middlewares do |t|
      t.belongs_to :route, null: false, foreign_key: true
      t.string :type, null: false
      t.jsonb :options

      t.timestamps
    end
  end
end
