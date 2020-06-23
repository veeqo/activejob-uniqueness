# frozen_string_literal: true

describe ActiveJob::Uniqueness::LockKey, '#wildcard_key' do
  subject { lock_key.wildcard_key }

  context 'when job_class_name is given' do
    context 'when no arguments given' do
      let(:lock_key) { described_class.new(job_class_name: 'FooJob') }

      it { is_expected.to eq 'activejob_uniqueness:foo_job:*' }
    end

    context 'when empty arguments given' do
      let(:lock_key) { described_class.new(job_class_name: 'FooJob', arguments: []) }

      it { is_expected.to eq 'activejob_uniqueness:foo_job:*' }
    end

    context 'when arguments given' do
      let(:lock_key) { described_class.new(job_class_name: 'FooJob', arguments: %w[bar baz]) }

      it { is_expected.to eq 'activejob_uniqueness:foo_job:516d664ce543e63aec2377e2127d649c*' }
    end
  end

  context 'when no job_class_name is given' do
    let(:lock_key) { described_class.new }

    it { is_expected.to eq 'activejob_uniqueness:*' }
  end
end
