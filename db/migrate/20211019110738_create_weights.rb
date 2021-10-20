class CreateWeights < ActiveRecord::Migration[6.1]
  def change
    create_table :weights do |t|
      t.belongs_to :route
      t.belongs_to :service
      t.integer :weight
      t.timestamps
    end
  end
end
