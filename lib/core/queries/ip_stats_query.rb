require_relative '../../system/import'
require_relative '../errors'

module Core
  module Queries
    class IpStatsQuery
      include Framework::Action
      include System::Import['core.ips', 'core.ip_checks', 'core.ip_states']

      input do
        required(:id).filled(:integer)
        required(:time_from).filled(:time)
        required(:time_to).filled(:time)
      end

      def call(input)
        time_from = input[:time_from]
        time_to = input[:time_to]

        raise ArgumentError, 'time_to must be greater than time_from' if time_to <= time_from

        ip = ips.find(input[:id])
        raise Core::Errors::NotFound, 'ip not found' unless ip

        effective_from = [time_from, ip.created_at].max
        effective_to = time_to

        raise ArgumentError, 'no measurements in the specified period' if effective_to <= effective_from

        stats = fetch_ip_check_stats(ip_id: ip.id, from: effective_from, to: effective_to)

        raise ArgumentError, 'no measurements in the specified period' if stats[:total_checks].zero?

        stats
      end

      private

      def fetch_ip_check_stats(ip_id:, from:, to:)
        ip_states_ds = ip_states.dataset

        ds = ip_checks.dataset
          .where(ip_id: ip_id)
          .where { checked_at >= from }
          .where { checked_at < to }
          .where do
            exists(
              ip_states_ds
                .where(ip_id: ip_id)
                .where(state: 'enabled')
                .where { started_at <= checked_at }
                .where { coalesce(ended_at, Sequel.lit("'infinity'::timestamptz")) > checked_at }
                .select(1)
            )
          end

        row = ds.select(
          Sequel.function(:count, Sequel.lit('*')).as(:total_checks),
          Sequel.lit('COUNT(*) FILTER (WHERE success)').as(:success_checks),
          Sequel.lit('COUNT(*) FILTER (WHERE NOT success)').as(:failed_checks),
          Sequel.lit('CASE WHEN COUNT(*) = 0 THEN 0.0 ELSE (COUNT(*) FILTER (WHERE NOT success) * 100.0 / COUNT(*)) END').as(:packet_loss_percent),
          Sequel.lit('AVG(rtt_ms) FILTER (WHERE success)').as(:avg_rtt_ms),
          Sequel.lit('MIN(rtt_ms) FILTER (WHERE success)').as(:min_rtt_ms),
          Sequel.lit('MAX(rtt_ms) FILTER (WHERE success)').as(:max_rtt_ms),
          Sequel.lit('PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rtt_ms) FILTER (WHERE success)').as(:median_rtt_ms),
          Sequel.lit('STDDEV_POP(rtt_ms) FILTER (WHERE success)').as(:stddev_rtt_ms)
        ).first

        {
          total_checks: row[:total_checks].to_i,
          success_checks: row[:success_checks].to_i,
          failed_checks: row[:failed_checks].to_i,
          packet_loss_percent: row[:packet_loss_percent].to_f,
          avg_rtt_ms: row[:avg_rtt_ms],
          min_rtt_ms: row[:min_rtt_ms],
          max_rtt_ms: row[:max_rtt_ms],
          median_rtt_ms: row[:median_rtt_ms],
          stddev_rtt_ms: row[:stddev_rtt_ms]
        }
      end
    end
  end
end
