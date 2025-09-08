class FixRoutesScheme < ActiveRecord::Migration[8.0]
  def change
    change_table :routes, bulk: true do |t|
      t.remove :labels, type: :jsonb
      t.remove :source_proto, type: :string
      t.remove :destination_proto, type: :string
    end

    reversible do |dir|
      dir.up do
        execute "ALTER TABLE routes " \
                "ALTER COLUMN ip_version TYPE SMALLINT " \
                "USING ip_version::SMALLINT"
      end
      dir.down do
        execute "ALTER TABLE routes " \
                "ALTER COLUMN ip_version TYPE CHARACTER VARYING"
      end
    end
  end
end
