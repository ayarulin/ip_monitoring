require_relative 'app'
require_relative '../../system/container'

System::Container.finalize! if ENV['RUBY_ENV'] != 'test'

run Applications::Api::App
