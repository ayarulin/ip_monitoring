require_relative 'app'
require_relative '../../system/container'

System::Container.finalize! if ENV['RUBY_ENV'] == 'production'

run Applications::Api::App
