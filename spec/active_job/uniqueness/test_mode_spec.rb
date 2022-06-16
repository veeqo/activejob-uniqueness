# frozen_string_literal: true

describe ActiveJob::Uniqueness, '.test_mode!', type: :integration do
  let(:job_class) do
    stub_active_job_class('MyJob') do
      unique :until_expired
    end
  end

  before do
    described_class.test_mode!
  end

  after do
    described_class.reset_manager!
  end

  it "doesn't lock in test mode" do
    job_class.perform_later(1, 2)
    expect(locks.count).to eq(0)
  end

  it 'locks after reset from test mode' do
    described_class.reset_manager!
    job_class.perform_later(1, 2)
    expect(locks.count).to eq(1)
  end
end
