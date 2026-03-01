require_relative '../../system/import'

module Core
  module Services
    class ReserveDueEnabledIps
      include System::Import['core.transaction', 'core.ips', 'core.ip_states']

      def call(limit:, now:, new_next_check_at:)
        limit = Integer(limit)
        raise ArgumentError, 'limit must be positive' if limit <= 0

        transaction.call do
          ip_states_ds = ip_states.dataset

          ds = ips.dataset
            .where(deleted_at: nil)
            .exclude(next_check_at: nil)
            .where { Sequel[:ips][:next_check_at] <= now }
            .where do
              exists(
                ip_states_ds
                  .where(ip_id: Sequel[:ips][:id])
                  .where(state: 'enabled', ended_at: nil)
                  .select(1)
              )
            end
            .order(:next_check_at)
            .limit(limit)
            .for_update
            .skip_locked
            .select(:id, :address, :created_at, :deleted_at, :next_check_at)

          rows = ds.all

          ids = rows.map { |r| r[:id] }

          ips.dataset.where(id: ids).update(next_check_at: new_next_check_at) unless ids.empty?

          rows.map do |r|
            Core::Entities::Ip.new(
              id: r[:id],
              address: r[:address],
              created_at: r[:created_at],
              deleted_at: r[:deleted_at],
              next_check_at: r[:next_check_at]
            )
          end
        end
      end
    end
  end
end
