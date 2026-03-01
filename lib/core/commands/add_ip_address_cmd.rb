require_relative '../../system/import'

module Core
  module Commands
    class AddIpAddressCmd
      include Framework::Action
      include System::Import['core.ips', 'core.ip_states', 'core.transaction']

      input do
        required(:ip).filled(:string)
        required(:enabled).filled(:bool)
      end

      def call(input)
        now = Time.now.utc
        next_check_at = input[:enabled] ? now : nil

        ip = Core::Entities::Ip.new(
          address: input[:ip],
          created_at: now,
          deleted_at: nil,
          next_check_at: next_check_at
        )

        transaction.call do
          ip = ips.save(ip)
          state = input[:enabled] ? 'enabled' : 'disabled'
          ip_state = Core::Entities::IpState.new(
            ip_id: ip.id,
            state: state,
            started_at: now,
            ended_at: nil
          )

          ip_states.save(ip_state)
        end

        ip.id
      rescue Sequel::UniqueConstraintViolation
        raise ArgumentError, 'already exists'
      end
    end
  end
end
