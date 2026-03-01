module Core
  module Dao
    class IpStates
      def initialize(db:)
        @db = db
        @dataset = @db[:ip_states]
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

      def active_for_ip(ip_id:)
        row = @dataset.where(ip_id: ip_id, ended_at: nil).first
        row && build_entity(row)
      end

      private

      def insert_entity(entity)
        id = @dataset.insert(
          ip_id: entity.ip_id,
          state: entity.state,
          started_at: entity.started_at,
          ended_at: entity.ended_at
        )

        Core::Entities::IpState.new(
          id: id,
          ip_id: entity.ip_id,
          state: entity.state,
          started_at: entity.started_at,
          ended_at: entity.ended_at
        )
      end

      def update_entity(entity)
        updated = @dataset
          .where(id: entity.id)
          .update(
            state: entity.state,
            started_at: entity.started_at,
            ended_at: entity.ended_at
          )

        return nil if updated.zero?

        entity
      end

      def build_entity(row)
        Core::Entities::IpState.new(
          id: row[:id],
          ip_id: row[:ip_id],
          state: row[:state],
          started_at: row[:started_at],
          ended_at: row[:ended_at]
        )
      end
    end
  end
end
