require 'dry-struct'
module Core
  module Entities
    class IpState < Dry::Struct
      Types = Core::Types

      transform_keys(&:to_sym)

      attribute? :id, Types::Id.optional
      attribute  :ip_id, Types::Id
      attribute  :state, Types::IPState
      attribute  :started_at, Types::Time
      attribute? :ended_at, Types::Time.optional

      def close(time)
        self.class.new(to_h.merge(ended_at: time))
      end
    end
  end
end
