module Core
  module Commands
    class AddIpAddressCmd
      include Framework::Action

      def initialize(ips:, ip_states:, transaction:)
        @ips = ips
        @ip_states = ip_states
        @transaction = transaction
      end

      input do
        required(:ip).filled(:string)
        required(:enabled).filled(:bool)
      end

      def call(input)
        now = Time.now.utc

        ip = Core::Entities::Ip.new(
          address: input[:ip],
          created_at: now,
          deleted_at: nil
        )

        @transaction.call do
          ip = @ips.save(ip)
          state = input[:enabled] ? 'enabled' : 'disabled'
          ip_state = Core::Entities::IpState.new(
            ip_id: ip.id,
            state: state,
            started_at: now,
            ended_at: nil
          )

          @ip_states.save(ip_state)
        end

        nil
      rescue Sequel::UniqueConstraintViolation
        raise ArgumentError, 'already exists'
      end
    end
  end
end
