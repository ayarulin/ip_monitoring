require_relative '../../system/import'
require_relative '../errors'

module Core
  module Commands
    class DeleteIpCmd
      include Framework::Action
      include System::Import['core.ips', 'core.ip_states', 'core.transaction']

      input do
        required(:id).filled(:integer)
      end

      def call(input)
        now = Time.now.utc

        ip = ips.find(input[:id])
        raise Core::Errors::NotFound, 'ip not found' unless ip

        transaction.call do
          current_state = ip_states.find_active(ip.id)

          if current_state
            current_state = current_state.close(now)
            ip_states.save(current_state)
          end

          ip = ip.set_deleted(now)
          ip = ip.set_next_check_at(nil)

          ips.save(ip)
        end

        nil
      end
    end
  end
end
