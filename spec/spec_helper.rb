require 'bundler/setup'
require 'rspec'
require 'sequel'
require 'sequel/extensions/migration'
require 'database_cleaner-sequel'
require_relative '../lib/boot'
require_relative '../lib/system/container'

env = ENV['RUBY_ENV']

abort "Refusing to run specs when RUBY_ENV=#{env.inspect} (expected 'test')" if env != 'test'

db_url = ENV['DATABASE_URL']

if db_url && !db_url.include?('_test')
  abort "Refusing to run specs against non-test database (DATABASE_URL=#{db_url.inspect})"
end

DatabaseCleaner.allow_remote_database_url = true

RSpec.configure do |config|
  config.order = :random
  config.formatter = :documentation

  config.before(:suite) do
    DatabaseCleaner[:sequel].db = System::Container['infrastructure.db']
    DatabaseCleaner[:sequel].strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning { example.run }
  end

  config.before(:each, :skip_ci) do
    skip 'Skipped in CI environment' if ENV['CI']
  end

  config.after(:suite) do
    System::Container['infrastructure.db']&.disconnect
  end
end
