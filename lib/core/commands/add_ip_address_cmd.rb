module Core
  module Commands
    class AddIpAddressCmd
      include Framework::Action

      def initialize(ips:, ip_states:)
        @ips = ips
        @ip_states = ip_states
      end

      input do
        required(:ip).filled(:string)
        required(:enabled).filled(:bool)
      end

      def call(input)
        now = Time.now.utc
        entity = Core::Entities::Ip.new(
          id: nil,
          address: input[:ip],
          created_at: now,
          deleted_at: nil
        )

        saved_ip = @ips.save(entity)
        state = input[:enabled] ? 'enabled' : 'disabled'
        ip_state = Core::Entities::IpState.new(
          id: nil,
          ip_id: saved_ip.id,
          state: state,
          started_at: now,
          ended_at: nil
        )

        @ip_states.save(ip_state)

        nil
      rescue Sequel::UniqueConstraintViolation
        raise ArgumentError, 'already exists'
      end
    end
  end
end
