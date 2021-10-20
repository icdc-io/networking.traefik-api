class UpdateRoutes < ActiveRecord::Migration[6.1]
  def change
    add_column :routes, :owner_email, :string
  end
end
