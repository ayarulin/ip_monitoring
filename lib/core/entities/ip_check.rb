require 'dry-struct'

module Core
  module Entities
    class IpCheck < Dry::Struct
      Types = Core::Types

      transform_keys(&:to_sym)

      attribute? :id, Types::Id.optional
      attribute  :ip_id, Types::Id
      attribute  :checked_at, Types::Time
      attribute  :success, Types::Bool
      attribute? :rtt_ms, Types::Integer.optional
    end
  end
end
