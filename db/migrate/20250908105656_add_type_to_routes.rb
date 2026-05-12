class AddTypeToRoutes < ActiveRecord::Migration[8.0]
  def change
    add_column :routes, :type, :string, null: true

    reversible do |dir|
      dir.up do
        execute "UPDATE routes SET type = CASE WHEN tls_termination = 'passthrough' THEN 'Route::Tcp' ELSE 'Route::Http' END"
      end
    end

    change_column_null :routes, :type, false
  end
end
