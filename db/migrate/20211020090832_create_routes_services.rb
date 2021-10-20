class CreateRoutesServices < ActiveRecord::Migration[6.1]
  def change
    create_table :routes_services do |t|
      t.belongs_to :route
      t.belongs_to :service
      t.string :balance_type
      t.float :value
      t.timestamps
    end
  end
end
