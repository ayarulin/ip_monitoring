require 'dry-types'
require 'ipaddr'

module Core::Types
  include Dry.Types()

  Id = Coercible::Integer
  Time = Params::Time
  Bool = Params::Bool
  IPAddress = Constructor(IPAddr) do |value|
    case value
    when IPAddr
      value
    when String
      IPAddr.new(value.strip)
    else
      raise TypeError, "unexpected IP address type: #{value.class}"
    end
  end
end
