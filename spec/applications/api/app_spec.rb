require 'spec_helper'
require 'json'
require 'rack/test'
require_relative '../../../lib/applications/api/app'

RSpec.describe Applications::Api::App do
  include Rack::Test::Methods

  def app
    described_class
  end

  it 'responds to POST /ips' do
    header 'CONTENT_TYPE', 'application/json'
    post '/ips', { ip: '8.8.8.8', enabled: true }.to_json

    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)).to eq('status' => 'ok')
  end

  it 'responds to POST /ips/:id/enable' do
    db = System::Container['infrastructure.db']
    add_cmd = System::Container['core.add_ip_address_cmd']

    add_cmd.call(ip: '8.8.8.8', enabled: false)
    ip_row = db[:ips].where(address: '8.8.8.8').first

    post "/ips/#{ip_row[:id]}/enable"

    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)).to eq('status' => 'ok')
  end

  it 'responds to POST /ips/:id/disable' do
    db = System::Container['infrastructure.db']
    add_cmd = System::Container['core.add_ip_address_cmd']

    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first

    post "/ips/#{ip_row[:id]}/disable"

    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)).to eq('status' => 'ok')
  end

  it 'returns 404 for unknown ip id on enable' do
    post '/ips/999999/enable'
    expect(last_response.status).to eq(404)
    expect(JSON.parse(last_response.body)).to have_key('error')
  end

  it 'returns 404 for unknown ip id on disable' do
    post '/ips/999999/disable'
    expect(last_response.status).to eq(404)
    expect(JSON.parse(last_response.body)).to have_key('error')
  end

  it 'responds to DELETE /ips/:id' do
    db = System::Container['infrastructure.db']
    add_cmd = System::Container['core.add_ip_address_cmd']

    add_cmd.call(ip: '8.8.8.8', enabled: true)
    ip_row = db[:ips].where(address: '8.8.8.8').first

    delete "/ips/#{ip_row[:id]}"

    expect(last_response.status).to eq(200)
    expect(JSON.parse(last_response.body)).to eq('status' => 'ok')
  end

  it 'returns 404 for unknown ip id on delete' do
    delete '/ips/999999'
    expect(last_response.status).to eq(404)
    expect(JSON.parse(last_response.body)).to have_key('error')
  end

  describe 'GET /ips/:id/stats' do
    it 'responds to GET /ips/:id/stats' do
      time_from = Time.now.utc.iso8601
      time_to = (Time.now.utc + 60).iso8601
      get '/ips/123/stats', { time_from: time_from, time_to: time_to }

      expect(last_response.status).to eq(404)
    end
  end
end
