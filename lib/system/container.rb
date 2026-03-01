require 'dry/system'

module System
  class Container < Dry::System::Container
    configure do |config|
      config.name = :ip_monitoring
      config.root = File.expand_path('../..', __dir__)
    end
  end
end

System::Container.register('infrastructure.db', memoize: true) do
  Infrastructure::Db::Connection.build
end

System::Container.register('core.ips') do
  Core::Dao::Ips.new(db: System::Container['infrastructure.db'])
end

System::Container.register('core.ip_states') do
  Core::Dao::IpStates.new(db: System::Container['infrastructure.db'])
end

System::Container.register('core.transaction') do
  Core::Services::Transaction.new(db: System::Container['infrastructure.db'])
end

System::Container.register('core.add_ip_address_cmd') do
  Core::Commands::AddIpAddressCmd.new
end

System::Container.register('core.change_ip_state_cmd') do
  Core::Commands::ChangeIpStateCmd.new
end
