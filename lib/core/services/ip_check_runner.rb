require_relative '../../system/import'

module Core
  module Services
    class IpCheckRunner
      include System::Import['core.ip_checks', 'infrastructure.ping_checker']

      def call(ip:, checked_at:)
        result = ping_checker.call(ip.address)

        ip_checks.save(
          Core::Entities::IpCheck.new(
            ip_id: ip.id,
            checked_at: checked_at,
            success: result.fetch(:success),
            rtt_ms: result.fetch(:rtt_ms)
          )
        )
      end
    end
  end
end
