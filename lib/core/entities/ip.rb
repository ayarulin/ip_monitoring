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
      attribute? :next_check_at, Types::Time.optional

      def set_deleted(time)
        self.class.new(to_h.merge(deleted_at: time))
      end

      def set_next_check_at(time)
        self.class.new(to_h.merge(next_check_at: time))
      end
    end
  end
end
