require 'open3'
require 'ipaddr'

module Infrastructure
  module Ping
    class PingChecker
      def initialize(timeout_sec:)
        @timeout_sec = Integer(timeout_sec)
        raise ArgumentError, 'timeout_sec must be positive' if @timeout_sec <= 0
      end

      # Returns a Hash:
      # - success: boolean
      # - rtt_ms: integer or nil
      def call(address)
        ip = normalize_address(address)
        cmd = build_cmd(ip)

        stdout, _stderr, status = Open3.capture3(*cmd)

        return { success: false, rtt_ms: nil } unless status.success?

        rtt_ms = parse_rtt_ms(stdout)
        { success: !rtt_ms.nil?, rtt_ms: rtt_ms }
      rescue IPAddr::InvalidAddressError, TypeError
        { success: false, rtt_ms: nil }
      end

      private

      def build_cmd(ip)
        family_flag = ip.ipv6? ? '-6' : '-4'

        # iputils-ping (Linux):
        # -c 1 : send 1 packet
        # -n   : numeric output
        # -W N : timeout for reply (seconds)
        # -w N : deadline (seconds)
        ['ping', family_flag, '-n', '-c', '1', '-W', @timeout_sec.to_s, '-w', @timeout_sec.to_s, ip.to_s]
      end

      def normalize_address(address)
        case address
        when IPAddr
          address
        else
          IPAddr.new(address.to_s)
        end
      end

      def parse_rtt_ms(output)
        # Example line: "64 bytes from 8.8.8.8: icmp_seq=1 ttl=117 time=14.2 ms"
        m = output.match(/\btime=(?<ms>[0-9]+(?:\.[0-9]+)?)\s*ms\b/i)
        return nil unless m

        # TODO: уточнить нужна ли десятичная точность
        m[:ms].to_f.round
      end
    end
  end
end
