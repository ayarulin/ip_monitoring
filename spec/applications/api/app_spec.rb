require 'spec_helper'
require 'json'
require 'rack/test'
require_relative '../../../applications/api/app'

RSpec.describe Applications::Api::App do
  include Rack::Test::Methods

  def app
    described_class
  end

  before(:each) do
    described_class::DB[:ips].delete
  end

  it 'responds to POST /ips' do
    header 'CONTENT_TYPE', 'application/json'
    post '/ips', { ip: '8.8.8.8', enabled: true }.to_json

    expect(last_response.status).to eq(201)
    expect(JSON.parse(last_response.body)).to eq('status' => 'ok')
  end
end
