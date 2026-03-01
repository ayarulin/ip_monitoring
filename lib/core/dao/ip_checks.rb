module Core
  module Dao
    class IpChecks
      def initialize(db:)
        @db = db
        @dataset = @db[:ip_checks]
      end

      def save(entity)
        if entity.id.nil?
          insert_entity(entity)
        else
          update_entity(entity)
        end
      end

      def find(id:)
        row = @dataset.where(id: id).first
        return nil unless row

        build_entity(row)
      end

      def list
        @dataset.all.map { |row| build_entity(row) }
      end

      private

      def insert_entity(entity)
        id = @dataset.insert(
          ip_id: entity.ip_id,
          checked_at: entity.checked_at,
          success: entity.success,
          rtt_ms: entity.rtt_ms
        )

        Core::Entities::IpCheck.new(
          id: id,
          ip_id: entity.ip_id,
          checked_at: entity.checked_at,
          success: entity.success,
          rtt_ms: entity.rtt_ms
        )
      end

      def update_entity(entity)
        updated = @dataset
          .where(id: entity.id)
          .update(
            ip_id: entity.ip_id,
            checked_at: entity.checked_at,
            success: entity.success,
            rtt_ms: entity.rtt_ms
          )

        return nil if updated.zero?

        entity
      end

      def build_entity(row)
        Core::Entities::IpCheck.new(
          id: row[:id],
          ip_id: row[:ip_id],
          checked_at: row[:checked_at],
          success: row[:success],
          rtt_ms: row[:rtt_ms]
        )
      end
    end
  end
end
