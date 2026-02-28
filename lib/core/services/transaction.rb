module Core
  module Services
    class Transaction
      def initialize(db:)
        @db = db
      end

      def call(&block)
        @db.transaction(&block)
      end
    end
  end
end
