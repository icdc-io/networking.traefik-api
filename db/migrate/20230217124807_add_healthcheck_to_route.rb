class AddHealthcheckToRoute < ActiveRecord::Migration[6.1]
  def change
    add_column :routes, :healthcheck_enabled, :boolean, default: false
    add_reference :healthchecks, :route, foreign_key: true
  end
end
