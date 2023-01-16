# frozen_string_literal: true

describe ActiveJob::Uniqueness, '.lock_manager', type: :integration do
  let(:lock_manager) { described_class.lock_manager }
  let(:pool_settings) { {} }
  let(:redis_connection) { lock_manager.instance_variable_get(:@servers).first.instance_variable_get(:@redis) }

  before do
    described_class.reset_manager!
    described_class.configure do |c|
      c.pool = pool_settings
    end
  end

  after do
    described_class.reset_config!
    described_class.reset_manager!
  end

  it 'does not use connection_pool by default' do
    expect(redis_connection.class).to eq(Redis)
  end

  context 'with pool' do
    let(:pool_settings) { { size: 3 } }

    it 'uses connection_pool' do
      expect(redis_connection.class).to eq(ConnectionPool)
    end

    it 'uses size from config' do
      expect(redis_connection.size).to eq(3)
    end

    it 'sets timeout from default setting' do
      expect(redis_connection.instance_variable_get(:@timeout)).to eq(1)
    end

    context 'when custom url is provided' do
      let(:pool_settings) { { url: 'redis://localhost:6379/10' } }

      it 'uses custom url instead of default one' do
        redis_connection.with do |conn|
          expect(conn.inspect).to match(%r{for redis://localhost:6379/10})
        end
      end
    end
  end
end
