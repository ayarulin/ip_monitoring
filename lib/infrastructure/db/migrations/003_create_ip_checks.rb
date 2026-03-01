Sequel.migration do
  up do
    create_table(:ip_checks) do
      primary_key :id
      foreign_key :ip_id, :ips, null: false
      column :checked_at, :timestamptz, null: false
      column :success, :boolean, null: false
      column :rtt_ms, :integer, null: true

      index :ip_id
      index [:ip_id, :checked_at]
    end
  end
end
