Sequel.migration do
  up do
    alter_table(:ips) do
      add_column :next_check_at, :timestamptz, null: true

      add_index :next_check_at
    end
  end
end
