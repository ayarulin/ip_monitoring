require 'json'
require 'roda'

require_relative '../../boot.rb'
require_relative '../../system/container'

module Applications
  module Api
    class App < Roda
      plugin :json
      plugin :json_parser
      plugin :error_handler

      def self.container
        System::Container
      end

      error do |e|
        case e
        when Framework::Action::InputError
          response.status = 422
          { error: e.message, details: e.errors }
        when ArgumentError
          response.status = 409
          { error: e.message }
        else
          raise e
        end
      end

      route do |r|
        r.post 'ips' do
          self.class.container['core.add_ip_address_cmd'].call(r.params)

          response.status = 201
          { status: 'ok' }
        end
      end
    end
  end
end
