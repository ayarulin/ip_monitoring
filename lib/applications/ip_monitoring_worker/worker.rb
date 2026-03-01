require_relative '../../system/import'

module Applications
  module IpMonitoringWorker
    class Worker
      include System::Import['core.reserve_due_enabled_ips', 'core.ip_check_runner']

      def initialize(
        check_interval_sec:,
        poll_interval_sec:,
        batch_size:,
        threads:
      )
        @check_interval_sec = Integer(check_interval_sec)
        @poll_interval_sec = Float(poll_interval_sec)
        @batch_size = Integer(batch_size)
        @threads = Integer(threads)

        raise ArgumentError, 'check_interval_sec must be positive' if @check_interval_sec <= 0
        raise ArgumentError, 'poll_interval_sec must be positive' if @poll_interval_sec <= 0
        raise ArgumentError, 'batch_size must be positive' if @batch_size <= 0
        raise ArgumentError, 'threads must be positive' if @threads <= 0
      end

      def run
        require 'concurrent-ruby'

        pool = Concurrent::FixedThreadPool.new(@threads)

        warn("ip_monitoring_worker started threads=#{@threads} batch=#{@batch_size} interval=#{@check_interval_sec}s")

        loop do
          now = Time.now.utc
          due = reserve_batch(now)

          if due.empty?
            sleep(@poll_interval_sec)
          else
            process_batch(due, pool)
          end
        end
      ensure
        pool&.shutdown
        pool&.wait_for_termination
      end

      private

      def reserve_batch(now)
        reserve_due_enabled_ips.call(
          limit: @batch_size,
          now: now,
          new_next_check_at: now + @check_interval_sec
        )
      end

      def process_batch(ips, pool)
        latch = Concurrent::CountDownLatch.new(ips.size)

        ips.each do |ip|
          pool.post do
            ip_check_runner.call(ip: ip, checked_at: Time.now.utc)
          rescue StandardError => e
            warn("ip_check failed ip_id=#{ip.id} error=#{e.class}: #{e.message}")
          ensure
            latch.count_down
          end
        end

        latch.wait
      end
    end
  end
end
