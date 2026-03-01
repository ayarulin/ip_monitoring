require 'spec_helper'
require_relative '../../../lib/core/queries/get_ip_stats_query'

RSpec.describe Core::Queries::GetIpStatsQuery do
  let(:db) { System::Container['infrastructure.db'] }
  let(:add_cmd) { System::Container['core.add_ip_address_cmd'] }
  let(:ip_checks) { System::Container['core.ip_checks'] }

  def create_ip_check(ip_id, checked_at, success, rtt_ms)
    ip_checks.save(
      Core::Entities::IpCheck.new(
        ip_id: ip_id,
        checked_at: checked_at,
        success: success,
        rtt_ms: rtt_ms
      )
    )
  end

  it 'returns stats for ip with successful and failed checks' do
    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first
    ip_id = ip_row[:id]

    created_at = ip_row[:created_at]
    create_ip_check(ip_id, created_at + 60, true, 10)
    create_ip_check(ip_id, created_at + 90, true, 20)
    create_ip_check(ip_id, created_at + 110, false, nil)

    result = subject.call(
      id: ip_id,
      time_from: created_at + 30,
      time_to: created_at + 120
    )

    expect(result[:total_checks]).to eq(3)
    expect(result[:success_checks]).to eq(2)
    expect(result[:failed_checks]).to eq(1)
    expect(result[:packet_loss_percent]).to be_within(0.01).of(33.33)
    expect(result[:avg_rtt_ms]).to be_within(0.01).of(15.0)
    expect(result[:min_rtt_ms]).to eq(10)
    expect(result[:max_rtt_ms]).to eq(20)
    expect(result[:median_rtt_ms]).to eq(15)
    expect(result[:stddev_rtt_ms]).to be > 0
  end

  it 'returns stats with null rtt when all checks failed' do
    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first
    ip_id = ip_row[:id]

    created_at = ip_row[:created_at]
    create_ip_check(ip_id, created_at + 60, false, nil)
    create_ip_check(ip_id, created_at + 90, false, nil)

    result = subject.call(
      id: ip_id,
      time_from: created_at + 30,
      time_to: created_at + 120
    )

    expect(result[:total_checks]).to eq(2)
    expect(result[:success_checks]).to eq(0)
    expect(result[:failed_checks]).to eq(2)
    expect(result[:packet_loss_percent]).to eq(100.0)
    expect(result[:avg_rtt_ms]).to be_nil
    expect(result[:min_rtt_ms]).to be_nil
    expect(result[:max_rtt_ms]).to be_nil
    expect(result[:median_rtt_ms]).to be_nil
    expect(result[:stddev_rtt_ms]).to be_nil
  end

  it 'raises NotFound when ip does not exist' do
    expect do
      subject.call(id: 999_999, time_from: Time.now.utc, time_to: Time.now.utc + 60)
    end.to raise_error(Core::Errors::NotFound)
  end

  it 'raises NotFound when ip is deleted' do
    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first
    ip_id = ip_row[:id]

    System::Container['core.delete_ip_cmd'].call(id: ip_id)

    expect do
      subject.call(id: ip_id, time_from: Time.now.utc, time_to: Time.now.utc + 60)
    end.to raise_error(Core::Errors::NotFound)
  end

  it 'raises ArgumentError when no measurements in period' do
    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first
    ip_id = ip_row[:id]

    created_at = ip_row[:created_at]

    expect do
      subject.call(id: ip_id, time_from: created_at + 30, time_to: created_at + 120)
    end.to raise_error(ArgumentError, /no measurements/)
  end

  it 'raises ArgumentError when time_to is not greater than time_from' do
    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first
    ip_id = ip_row[:id]

    created_at = ip_row[:created_at]

    expect do
      subject.call(id: ip_id, time_from: created_at + 120, time_to: created_at + 60)
    end.to raise_error(ArgumentError, /time_to must be greater/)
  end

  it 'only counts checks during enabled intervals' do
    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first
    ip_id = ip_row[:id]

    created_at = ip_row[:created_at]

    create_ip_check(ip_id, created_at + 5, true, 10)
    create_ip_check(ip_id, created_at + 15, true, 5)
    create_ip_check(ip_id, created_at + 25, true, 20)

    db[:ip_states].where(ip_id: ip_id, ended_at: nil).update(ended_at: created_at + 10)
    db[:ip_states].insert(ip_id: ip_id, state: 'disabled', started_at: created_at + 10, ended_at: created_at + 20)
    db[:ip_states].insert(ip_id: ip_id, state: 'enabled', started_at: created_at + 20, ended_at: nil)

    result = subject.call(
      id: ip_id,
      time_from: created_at + 3,
      time_to: created_at + 30
    )

    expect(result[:total_checks]).to eq(2)
    expect(result[:avg_rtt_ms]).to be_within(0.01).of(15.0)
  end
end
