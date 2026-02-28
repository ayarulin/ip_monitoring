require 'spec_helper'

RSpec.describe Core::Commands::AddIpAddressCmd do
  let(:db) { System::Container['db'] }
  let(:command) { System::Container['core.add_ip_address_cmd'] }

  it 'saves new ip' do
    now = Time.utc(2026, 1, 2, 3, 4, 5)

    allow(Time).to receive(:now).and_return(now)

    command.call(ip: '8.8.8.8', enabled: true)

    row = db[:ips].where(address: '8.8.8.8').first
    state_row = db[:ip_states].where(ip_id: row[:id]).first

    expect(row).not_to be_nil
    expect(row[:address].to_s).to eq('8.8.8.8')
    expect(row[:created_at]).to eq(now)
    expect(row[:deleted_at]).to be_nil
    expect(state_row).not_to be_nil
    expect(state_row[:state]).to eq('enabled')
    expect(state_row[:started_at]).to eq(now)
    expect(state_row[:ended_at]).to be_nil
  end

  it 'saves disabled state when enabled is false' do
    now = Time.utc(2026, 2, 3, 4, 5, 6)

    allow(Time).to receive(:now).and_return(now)

    command.call(ip: '1.1.1.1', enabled: false)

    row = db[:ips].where(address: '1.1.1.1').first
    state_row = db[:ip_states].where(ip_id: row[:id]).first

    expect(state_row).not_to be_nil
    expect(state_row[:state]).to eq('disabled')
    expect(state_row[:started_at]).to eq(now)
    expect(state_row[:ended_at]).to be_nil
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
