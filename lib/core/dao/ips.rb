module Core
  module Dao
    class Ips
      def initialize(db:)
        @db = db
        @dataset = @db[:ips]
      end

      def save(entity)
        if entity.id.nil?
          insert_entity(entity)
        else
          update_entity(entity)
        end
      end

      def find(id:)
        row = scope.where(id: id).first
        return nil unless row

        build_entity(row)
      end

      def scope
        @dataset.where(deleted_at: nil)
      end

      def list
        scope.all.map { |row| build_entity(row) }
      end

      private

      def insert_entity(entity)
        id = @dataset.insert(
          address: entity.address.to_s,
          created_at: entity.created_at,
          deleted_at: entity.deleted_at
        )

        Core::Entities::Ip.new(
          id: id,
          address: entity.address,
          created_at: entity.created_at,
          deleted_at: entity.deleted_at
        )
      end

      def update_entity(entity)
        updated = @dataset
          .where(id: entity.id)
          .update(
            address: entity.address.to_s,
            deleted_at: entity.deleted_at
          )

        # TODO: raise record not found error
        return nil if updated.zero?

        entity
      end

      def build_entity(row)
        Core::Entities::Ip.new(
          id: row[:id],
          address: row[:address],
          created_at: row[:created_at],
          deleted_at: row[:deleted_at]
        )
      end
    end
  end
end
