require 'spec_helper'

RSpec.describe Core::Commands::ChangeIpStateCmd do
  let(:db) { System::Container['infrastructure.db'] }
  let(:command) { System::Container['core.change_ip_state_cmd'] }
  let(:add_cmd) { System::Container['core.add_ip_address_cmd'] }

  it 'switches from disabled to enabled' do
    t1 = Time.utc(2026, 1, 2, 3, 4, 5)
    t2 = Time.utc(2026, 1, 2, 3, 5, 6)

    allow(Time).to receive(:now).and_return(t1)
    add_cmd.call(ip: '8.8.8.8', enabled: false)
    ip_row = db[:ips].where(address: '8.8.8.8').first

    allow(Time).to receive(:now).and_return(t2)
    command.call(id: ip_row[:id], enabled: true)

    states = db[:ip_states].where(ip_id: ip_row[:id]).order(:id).all
    expect(states.size).to eq(2)

    disabled, enabled = states
    expect(disabled[:state]).to eq('disabled')
    expect(disabled[:started_at]).to eq(t1)
    expect(disabled[:ended_at]).to eq(t2)

    expect(enabled[:state]).to eq('enabled')
    expect(enabled[:started_at]).to eq(t2)
    expect(enabled[:ended_at]).to be_nil
  end

  it 'switches from enabled to disabled' do
    t1 = Time.utc(2026, 1, 2, 3, 4, 5)
    t2 = Time.utc(2026, 1, 2, 3, 5, 6)

    allow(Time).to receive(:now).and_return(t1)
    add_cmd.call(ip: '1.1.1.1', enabled: true)
    ip_row = db[:ips].where(address: '1.1.1.1').first

    allow(Time).to receive(:now).and_return(t2)
    command.call(id: ip_row[:id], enabled: false)

    states = db[:ip_states].where(ip_id: ip_row[:id]).order(:id).all
    expect(states.size).to eq(2)

    enabled, disabled = states
    expect(enabled[:state]).to eq('enabled')
    expect(enabled[:started_at]).to eq(t1)
    expect(enabled[:ended_at]).to eq(t2)

    expect(disabled[:state]).to eq('disabled')
    expect(disabled[:started_at]).to eq(t2)
    expect(disabled[:ended_at]).to be_nil
  end

  it 'does nothing when state is already enabled' do
    now = Time.utc(2026, 1, 2, 3, 4, 5)

    allow(Time).to receive(:now).and_return(now)
    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first

    expect do
      command.call(id: ip_row[:id], enabled: true)
    end.not_to(change { db[:ip_states].where(ip_id: ip_row[:id]).count })

    state = db[:ip_states].where(ip_id: ip_row[:id]).first
    expect(state[:state]).to eq('enabled')
    expect(state[:ended_at]).to be_nil
  end

  it 'does nothing when state is already disabled' do
    now = Time.utc(2026, 1, 2, 3, 4, 5)

    allow(Time).to receive(:now).and_return(now)
    add_cmd.call(ip: '8.8.8.8', enabled: false)
    ip_row = db[:ips].where(address: '8.8.8.8').first

    expect do
      command.call(id: ip_row[:id], enabled: false)
    end.not_to(change { db[:ip_states].where(ip_id: ip_row[:id]).count })

    state = db[:ip_states].where(ip_id: ip_row[:id]).first
    expect(state[:state]).to eq('disabled')
    expect(state[:ended_at]).to be_nil
  end

  it 'raises NotFound error when ip does not exist' do
    expect do
      command.call(id: 999_999, enabled: true)
    end.to raise_error(Core::Errors::NotFound, 'ip not found')
  end

  it 'raises NotFound error when ip is deleted' do
    now = Time.utc(2026, 1, 2, 3, 4, 5)

    allow(Time).to receive(:now).and_return(now)
    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first

    db[:ips].where(id: ip_row[:id]).update(deleted_at: now)

    expect do
      command.call(id: ip_row[:id], enabled: false)
    end.to raise_error(Core::Errors::NotFound, 'ip not found')
  end

  it 'raises input error for missing params' do
    expect { command.call(id: 1) }
      .to raise_error(Framework::Action::InputError)
  end

  it 'raises input error for invalid id type' do
    expect { command.call(id: 'abc', enabled: true) }
      .to raise_error(Framework::Action::InputError)
  end
end
