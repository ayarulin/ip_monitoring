require 'dry-types'
require 'ipaddr'

module Core::Types
  include Dry.Types()

  Id = Coercible::Integer
  Time = Params::Time
  Bool = Params::Bool
end
