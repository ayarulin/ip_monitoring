require 'bundler/setup'
require 'rspec'
require 'sequel'
require 'sequel/extensions/migration'
require_relative '../lib/core'
require_relative '../lib/infrastructure'

RSpec.configure do |config|
  config.order = :random
  config.formatter = :documentation
end
