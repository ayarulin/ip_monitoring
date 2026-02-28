require 'json'
require 'roda'

require_relative '../../lib/boot'

module Applications
  module Api
    class App < Roda
      plugin :json
      plugin :json_parser
      plugin :error_handler

      DB = Infrastructure::Db::Connection.build

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
          cmd = Core::Commands::AddIpAddressCmd.new(
            ips: Core::Dao::Ips.new(db: DB)
          )

          cmd.call(r.params)

          response.status = 201
          { status: 'ok' }
        end
      end
    end
  end
end
