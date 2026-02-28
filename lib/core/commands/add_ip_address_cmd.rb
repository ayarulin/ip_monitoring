module Core
  module Commands
    class AddIpAddressCmd
      include Framework::Action

      def initialize(ips:)
        @ips = ips
      end

      input do
        required(:ip).filled(:string)
        required(:enabled).filled(:bool)
      end

      def call(input)
        entity = Core::Entities::Ip.new(
          id: nil,
          address: input[:ip],
          created_at: Time.now.utc,
          deleted_at: nil
        )

        @ips.save(entity)

        nil
      rescue Sequel::UniqueConstraintViolation
        raise ArgumentError, 'already exists'
      end
    end
  end
end
