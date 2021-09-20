class CreateRoutesServicesJoinTable < ActiveRecord::Migration[6.1]
  def change
    create_join_table :routes, :services do |t|
      t.index :route_id
      t.index :service_id
    end
  end
end
