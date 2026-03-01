require_relative '../../system/import'
require_relative '../errors'

module Core
  module Queries
    class GetIpStatsQuery
      include Framework::Action
      include System::Import['infrastructure.db', 'core.ips']

      input do
        required(:id).filled(:integer)
        required(:time_from).filled(:time)
        required(:time_to).filled(:time)
      end

      def call(input)
        time_from = input[:time_from]
        time_to = input[:time_to]

        raise ArgumentError, 'time_to must be greater than time_from' if time_to <= time_from

        ip = ips.find(id: input[:id])
        raise Core::Errors::NotFound, 'ip not found' unless ip

        effective_from = [time_from, ip.created_at].max
        effective_to = time_to

        raise ArgumentError, 'no measurements in the specified period' if effective_to <= effective_from

        stats = calculate_stats(ip_id: ip.id, from: effective_from, to: effective_to)

        raise ArgumentError, 'no measurements in the specified period' if stats[:total_checks].zero?

        stats
      end

      private

      def calculate_stats(ip_id:, from:, to:)
        sql = <<~SQL
          SELECT
            COUNT(*) AS total_checks,
            COUNT(*) FILTER (WHERE success) AS success_checks,
            COUNT(*) FILTER (WHERE NOT success) AS failed_checks,
            CASE WHEN COUNT(*) = 0 THEN 0.0 ELSE (COUNT(*) FILTER (WHERE NOT success) * 100.0 / COUNT(*)) END AS packet_loss_percent,
            AVG(rtt_ms) FILTER (WHERE success) AS avg_rtt_ms,
            MIN(rtt_ms) FILTER (WHERE success) AS min_rtt_ms,
            MAX(rtt_ms) FILTER (WHERE success) AS max_rtt_ms,
            PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY rtt_ms) FILTER (WHERE success) AS median_rtt_ms,
            STDDEV_POP(rtt_ms) FILTER (WHERE success) AS stddev_rtt_ms
          FROM ip_checks ic
          WHERE ic.ip_id = :ip_id
            AND ic.checked_at >= :from
            AND ic.checked_at < :to
            AND EXISTS (
              SELECT 1 FROM ip_states
              WHERE ip_id = ic.ip_id
                AND state = 'enabled'
                AND started_at <= ic.checked_at
                AND COALESCE(ended_at, 'infinity'::timestamptz) > ic.checked_at
            )
        SQL

        row = db.fetch(sql, ip_id: ip_id, from: from, to: to).first

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
