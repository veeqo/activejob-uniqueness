# frozen_string_literal: true

describe ActiveJob::Uniqueness::LockKey, '#lock_key' do
  subject { lock_key.lock_key }

  let(:lock_key) { described_class.new(job_class_name: job_class_name, arguments: arguments) }
  let(:job_class_name) { 'FooBarJob' }
  let(:arguments) { ['baz'] }

  context 'when default configuration is used' do
    it { is_expected.to eq 'activejob_uniqueness:foo_bar_job:143654a5f0a059a178924baf9b815ea6' }
  end

  context 'when job class has namespace' do
    let(:job_class_name) { 'Foo::BarJob' }

    it { is_expected.to eq 'activejob_uniqueness:foo/bar_job:143654a5f0a059a178924baf9b815ea6' }
  end

  context 'when custom lock_prefix is set' do
    before { allow(ActiveJob::Uniqueness.config).to receive(:lock_prefix).and_return('custom') }

    it { is_expected.to eq 'custom:foo_bar_job:143654a5f0a059a178924baf9b815ea6' }
  end

  context 'when custom digest_method is set' do
    before { allow(ActiveJob::Uniqueness.config).to receive(:digest_method).and_return(OpenSSL::Digest::SHA1) }

    it { is_expected.to eq 'activejob_uniqueness:foo_bar_job:c8246148dacbed08f65913be488195317569f8dd' }
  end

  context 'when nil arguments given' do
    let(:arguments) { nil }

    it { is_expected.to eq 'activejob_uniqueness:foo_bar_job:no_arguments' }
  end

  context 'when [] arguments given' do
    let(:arguments) { [] }

    it { is_expected.to eq 'activejob_uniqueness:foo_bar_job:no_arguments' }
  end
end
