require 'spec_helper'
require_relative '../../../lib/core/commands/add_ip_address_cmd'
require_relative '../../../lib/core/dao/ips'
require_relative '../../../lib/infrastructure/db/connection'

RSpec.describe Commands::AddIpAddressCmd do
  let(:db) { @db }
  let(:ips) { Core::Dao::Ips.new(db: db) }
  let(:command) { described_class.new(ips: ips) }

  before(:all) do
    @db = Infrastructure::Db::Connection.build
  end

  before(:each) do
    @db[:ips].delete
  end

  after(:all) do
    @db.disconnect if @db
  end

  it 'saves new ip' do
    now = Time.utc(2026, 1, 2, 3, 4, 5)

    allow(Time).to receive(:now).and_return(now)

    command.call(ip: '8.8.8.8', enabled: true)

    row = db[:ips].where(address: '8.8.8.8').first

    expect(row).not_to be_nil
    expect(row[:address].to_s).to eq('8.8.8.8')
    expect(row[:created_at]).to eq(now)
    expect(row[:deleted_at]).to be_nil
  end

  it 'raises argument error when address already exists' do
    command.call(ip: '8.8.8.8', enabled: true)

    expect { command.call(ip: '8.8.8.8', enabled: true) }
      .to raise_error(ArgumentError, 'already exists')
  end

  it 'raises input error for missing params' do
    expect { command.call(ip: '8.8.8.8') }
      .to raise_error(Framework::Action::InputError)
  end
end
