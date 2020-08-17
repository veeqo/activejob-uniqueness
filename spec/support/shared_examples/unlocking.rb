# frozen_string_literal: true

shared_examples_for 'no unlock attempts' do
  it 'does not try to unset any locks' do
    allow(ActiveJob::Uniqueness.lock_manager).to receive(:delete_locks)
    allow(ActiveJob::Uniqueness.lock_manager).to receive(:delete_lock)

    subject

    expect(ActiveJob::Uniqueness.lock_manager).not_to have_received(:delete_locks)
    expect(ActiveJob::Uniqueness.lock_manager).not_to have_received(:delete_lock)
  end
end
