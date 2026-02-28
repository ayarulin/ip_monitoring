require 'dry-struct'
module Core
  module Entities
    class Ip < Dry::Struct
      Types = Core::Types

      transform_keys(&:to_sym)

      attribute? :id, Types::Id.optional
      attribute  :address, Types::IPAddress
      attribute  :created_at, Types::Time
      attribute? :deleted_at, Types::Time.optional
    end
  end
end
