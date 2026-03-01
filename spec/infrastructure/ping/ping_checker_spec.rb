require 'spec_helper'
require_relative '../../../lib/infrastructure/ping/ping_checker'

RSpec.describe Infrastructure::Ping::PingChecker do
  let(:checker) { described_class.new(timeout_sec: 1) }

  describe '#call' do
    context 'when pinging reachable IPv4 address' do
      it 'returns success with rtt_ms' do
        result = checker.call('8.8.8.8')

        expect(result[:success]).to be true
        expect(result[:rtt_ms]).to be_a(Integer)
        expect(result[:rtt_ms]).to be > 0
      end
    end

    context 'when pinging reachable IPv4 address (Cloudflare)' do
      it 'returns success with rtt_ms' do
        result = checker.call('1.1.1.1')

        expect(result[:success]).to be true
        expect(result[:rtt_ms]).to be_a(Integer)
        expect(result[:rtt_ms]).to be > 0
      end
    end

    context 'when pinging unreachable address' do
      it 'returns failure without rtt_ms' do
        # 192.0.2.1 - из RFC 5737, зарезервирован для документации
        # Должен таймаутиться
        result = checker.call('192.0.2.1')

        expect(result[:success]).to be false
        expect(result[:rtt_ms]).to be_nil
      end
    end

    context 'when pinging non-routable multicast address' do
      it 'returns failure without rtt_ms' do
        # 224.0.0.1 - multicast, не должен отвечать
        result = checker.call('224.0.0.1')

        expect(result[:success]).to be false
        expect(result[:rtt_ms]).to be_nil
      end
    end

    context 'when given invalid address' do
      it 'returns failure without rtt_ms for malformed IP' do
        result = checker.call('not.an.ip.address')

        expect(result[:success]).to be false
        expect(result[:rtt_ms]).to be_nil
      end

      it 'returns failure without rtt_ms for empty string' do
        result = checker.call('')

        expect(result[:success]).to be false
        expect(result[:rtt_ms]).to be_nil
      end
    end

    context 'when given IPv6 address' do
      it 'returns success with rtt_ms for reachable IPv6' do
        # Cloudflare IPv6 DNS
        result = checker.call('2606:4700:4700::1111')

        # Может не работать в некоторых сетях без IPv6
        # Поэтому просто проверяем, что результат имеет правильную структуру
        expect(result).to have_key(:success)
        expect(result).to have_key(:rtt_ms)

        if result[:success]
          expect(result[:rtt_ms]).to be_a(Integer)
          expect(result[:rtt_ms]).to be > 0
        else
          expect(result[:rtt_ms]).to be_nil
        end
      end
    end
  end

  describe '#initialize' do
    it 'raises error for non-positive timeout' do
      expect { described_class.new(timeout_sec: 0) }
        .to raise_error(ArgumentError, /timeout_sec must be positive/)

      expect { described_class.new(timeout_sec: -1) }
        .to raise_error(ArgumentError, /timeout_sec must be positive/)
    end

    it 'accepts positive timeout' do
      expect { described_class.new(timeout_sec: 1) }.not_to raise_error
    end
  end
end
