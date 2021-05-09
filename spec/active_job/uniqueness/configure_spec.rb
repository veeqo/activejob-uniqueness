# frozen_string_literal: true

describe ActiveJob::Uniqueness, '.configure' do
  let(:config) { ActiveJob::Uniqueness::Configuration.new }
  let(:redis_url) { ENV.fetch('REDIS_URL', 'redis://localhost:6379') }

  before { allow(ActiveJob::Uniqueness).to receive(:config).and_return config }

  context 'when no configuration has been set' do
    subject { described_class.configure {} }

    it 'does not change the default configuration' do
      expect { subject }.to not_change { config.lock_ttl }.from(1.day)
                        .and not_change { config.lock_prefix }.from('activejob_uniqueness')
                        .and not_change { config.on_conflict }.from(:raise)
                        .and not_change { config.digest_method }.from(OpenSSL::Digest::MD5)
                        .and not_change { config.redlock_servers }.from([redis_url])
                        .and not_change { config.redlock_options }.from({})
                        .and not_change { config.lock_strategies }.from({})
    end
  end

  context 'when valid configuration has been set' do
    class self::MyStrategy < ActiveJob::Uniqueness::Strategies::Base; end

    subject do
      described_class.configure do |c|
        c.lock_ttl = 2.hours
        c.lock_prefix = 'foobar'
        c.on_conflict = :log
        c.digest_method = OpenSSL::Digest::SHA1
        c.redlock_servers = [Redis.current]
        c.redlock_options = { redis_timeout: 0.01, retry_count: 0 }
        c.lock_strategies = { my_strategy: self.class::MyStrategy }
      end
    end

    it 'changes the confguration' do
      expect { subject }.to change { config.lock_ttl }.from(1.day).to(2.hours)
                        .and change { config.lock_prefix }.from('activejob_uniqueness').to('foobar')
                        .and change { config.on_conflict }.from(:raise).to(:log)
                        .and change { config.digest_method }.from(OpenSSL::Digest::MD5).to(OpenSSL::Digest::SHA1)
                        .and change { config.redlock_servers }.from([redis_url]).to([Redis.current])
                        .and change { config.redlock_options }.from({}).to({ redis_timeout: 0.01, retry_count: 0 })
                        .and change { config.lock_strategies }.from({}).to({ my_strategy: self.class::MyStrategy })
    end
  end

  context 'when Proc on_conflict has been set' do
    subject do
      described_class.configure do |c|
        c.on_conflict = on_conflict_proc
      end
    end

    let(:on_conflict_proc) { ->(job) { job.logger.info 'Oops' } }

    it 'changes the confguration' do
      expect { subject }.to change { config.on_conflict }.from(:raise).to(on_conflict_proc)
    end
  end

  context 'when invalid on_conflict has been set' do
    subject do
      described_class.configure do |c|
        c.on_conflict = :panic
      end
    end

    it 'raises ActiveJob::Uniqueness::InvalidOnConflictAction' do
      expect { subject }.to raise_error(ActiveJob::Uniqueness::InvalidOnConflictAction, "Unexpected 'panic' action on conflict")
    end
  end
end
