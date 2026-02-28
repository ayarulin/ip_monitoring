require 'dry/auto_inject'
require_relative 'container'

module System
  Import = Dry::AutoInject(Container)
end
