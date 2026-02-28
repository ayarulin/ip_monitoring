Sequel.migration do
  up do
    create_table(:ip_states) do
      primary_key :id
      foreign_key :ip_id, :ips, null: false
      column :state, :text, null: false
      column :started_at, :timestamptz, null: false
      column :ended_at, :timestamptz, null: true
    end

    add_index :ip_states, :ip_id
    add_index :ip_states, :started_at
    add_index :ip_states, :ip_id, unique: true, where: { ended_at: nil }
  end
end
