require_relative '../../system/import'
require_relative '../errors'

module Core
  module Commands
    class ChangeIpStateCmd
      include Framework::Action
      include System::Import['core.ips', 'core.ip_states', 'core.transaction']

      input do
        required(:id).filled(:integer)
        required(:enabled).filled(:bool)
      end

      def call(input)
        now = Time.now.utc
        desired_state = input[:enabled] ? 'enabled' : 'disabled'

        ip = ips.find(input[:id])
        raise Core::Errors::NotFound, 'ip not found' unless ip

        transaction.call do
          current_state = ip_states.find_active(ip.id)

          return nil if current_state && current_state.state == desired_state

          if current_state
            current_state = current_state.close(now)
            ip_states.save(current_state)
          end

          new_state = Core::Entities::IpState.new(
            ip_id: ip.id,
            state: desired_state,
            started_at: now,
            ended_at: nil
          )

          ip_states.save(new_state)
        end

        nil
      end
    end
  end
end
