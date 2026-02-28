require 'dry/validation'

module Framework
  module Action
    class InputError < StandardError
      attr_reader :errors

      def initialize(errors)
        @errors = errors
        super("Invalid input: #{errors.inspect}")
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def input(&block)
        @contract_class = Class.new(Dry::Validation::Contract) do
          params(&block)
        end
      end

      def contract_class
        @contract_class or raise "Input contract not defined for #{name}"
      end

      def method_added(name)
        return unless name == :call
        return if @_wrapping_call

        @_wrapping_call = true

        remove_method :__original_call if instance_methods(false).include?(:__original_call)

        alias_method :__original_call, :call

        define_method(:call) do |raw_params|
          result = self.class.contract_class.new.call(raw_params)

          raise InputError.new(result.errors.to_h) if result.failure?

          __original_call(result.to_h)
        end

        @_wrapping_call = false
      end
    end
  end
end
