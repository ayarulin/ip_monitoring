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

System::Container.register('infrastructure.ping_checker', memoize: true) do
  Infrastructure::Ping::PingChecker.new(
    timeout_sec: ENV.fetch('IP_MONITORING_WORKER_PING_TIMEOUT_SEC')
  )
end

System::Container.register('core.ips') do
  Core::Dao::Ips.new(db: System::Container['infrastructure.db'])
end

System::Container.register('core.ip_states') do
  Core::Dao::IpStates.new(db: System::Container['infrastructure.db'])
end

System::Container.register('core.ip_checks') do
  Core::Dao::IpChecks.new(db: System::Container['infrastructure.db'])
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

System::Container.register('core.delete_ip_cmd') do
  Core::Commands::DeleteIpCmd.new
end

System::Container.register('core.ip_stats_query') do
  Core::Queries::IpStatsQuery.new
end

System::Container.register('core.ip_check_runner') do
  Core::Services::IpCheckRunner.new
end

System::Container.register('core.reserve_due_enabled_ips') do
  Core::Services::ReserveDueEnabledIps.new
end
