class ChangeTargetPortType < ActiveRecord::Migration[6.1]
  def change
    change_column :routes, :target_port, :integer
  end
end
