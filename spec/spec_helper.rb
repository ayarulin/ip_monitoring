require 'bundler/setup'
require 'rspec'
require 'sequel'
require 'sequel/extensions/migration'
require 'database_cleaner-sequel'
require_relative '../lib/boot'
require_relative '../lib/system/container'

DatabaseCleaner.allow_remote_database_url = true

RSpec.configure do |config|
  config.order = :random
  config.formatter = :documentation

  config.before(:suite) do
    DatabaseCleaner[:sequel].db = System::Container['db']
    DatabaseCleaner[:sequel].strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end

  config.after(:suite) do
    System::Container['db']&.disconnect
  end
end
