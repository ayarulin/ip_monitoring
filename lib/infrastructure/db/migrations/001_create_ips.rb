Sequel.migration do
  up do
    create_table(:ips) do
      primary_key :id
      column :address, :inet, null: false
      column :created_at, :timestamptz, null: false
      column :deleted_at, :timestamptz, null: true

      index :ips, :created_at
      index :ips, :address, unique: true, where: { deleted_at: nil }
    end
  end
end
