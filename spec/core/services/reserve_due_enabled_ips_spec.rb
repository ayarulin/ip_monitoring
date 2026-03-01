require 'spec_helper'
require_relative '../../../lib/core/services/reserve_due_enabled_ips'

RSpec.describe Core::Services::ReserveDueEnabledIps do
  let(:service) { System::Container['core.reserve_due_enabled_ips'] }
  let(:ips) { System::Container['core.ips'] }
  let(:ip_states) { System::Container['core.ip_states'] }
  let(:transaction) { System::Container['core.transaction'] }

  # Postgres timestamptz has microsecond precision, while Ruby Time can carry
  # nanoseconds. Normalize all expected timestamps to microseconds.
  def pg_time(t)
    Time.at(t.to_i, t.usec, :microsecond).utc
  end

  def insert_ip(address:, next_check_at:, enabled: true)
    now = pg_time(Time.now.utc)

    transaction.call do
      ip = ips.save(
        Core::Entities::Ip.new(
          address: address,
          created_at: now,
          deleted_at: nil,
          next_check_at: next_check_at
        )
      )

      ip_states.save(
        Core::Entities::IpState.new(
          ip_id: ip.id,
          state: enabled ? 'enabled' : 'disabled',
          started_at: now,
          ended_at: nil
        )
      )

      ip
    end
  end

  it 'reserves enabled IPs that are due and bumps next_check_at' do
    now = pg_time(Time.now.utc)
    prev_next_check_at = pg_time(now - 120)
    new_next_check_at = pg_time(now + 60)

    ip = insert_ip(address: '8.8.8.8', enabled: true, next_check_at: prev_next_check_at)

    reserved = service.call(limit: 10, now: now, new_next_check_at: new_next_check_at)

    expect(reserved.map(&:id)).to eq([ip.id])
    expect(reserved.first.next_check_at).to eq(prev_next_check_at)
    expect(ips.find(ip.id).next_check_at).to eq(new_next_check_at)
  end

  it 'does not reserve disabled IPs even if next_check_at is due' do
    now = pg_time(Time.now.utc)
    ip = insert_ip(address: '1.1.1.1', enabled: false, next_check_at: pg_time(now - 60))

    reserved = service.call(limit: 10, now: now, new_next_check_at: pg_time(now + 60))

    expect(reserved.map(&:id)).not_to include(ip.id)
  end

  it 'respects limit and reserves in next_check_at order' do
    now = pg_time(Time.now.utc)
    new_next_check_at = pg_time(now + 60)

    ip1 = insert_ip(address: '8.8.4.4', enabled: true, next_check_at: pg_time(now - 300))
    ip2 = insert_ip(address: '9.9.9.9', enabled: true, next_check_at: pg_time(now - 200))
    ip3 = insert_ip(address: '1.0.0.1', enabled: true, next_check_at: pg_time(now - 100))

    reserved = service.call(limit: 2, now: now, new_next_check_at: new_next_check_at)

    expect(reserved.map(&:id)).to eq([ip1.id, ip2.id])

    expect(ips.find(ip1.id).next_check_at).to eq(new_next_check_at)
    expect(ips.find(ip2.id).next_check_at).to eq(new_next_check_at)
    expect(ips.find(ip3.id).next_check_at).to eq(pg_time(now - 100))
  end

  it 'does not return already reserved IPs on the next call' do
    now = pg_time(Time.now.utc)
    ip = insert_ip(address: '8.8.8.8', enabled: true, next_check_at: pg_time(now - 60))

    first = service.call(limit: 10, now: now, new_next_check_at: pg_time(now + 60))
    second = service.call(limit: 10, now: now, new_next_check_at: pg_time(now + 60))

    expect(first.map(&:id)).to eq([ip.id])
    expect(second).to eq([])
  end
end
