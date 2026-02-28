Sequel.migration do
  up do
    create_table(:ip_states) do
      primary_key :id
      foreign_key :ip_id, :ips, null: false
      column :state, :text, null: false
      column :started_at, :timestamptz, null: false
      column :ended_at, :timestamptz, null: true

      index :ip_id
      index :started_at
      index :ip_id, unique: true, where: { ended_at: nil }, name: :ip_states_ip_id_active_idx
    end
  end
end
