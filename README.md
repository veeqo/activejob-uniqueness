# Job uniqueness for ActiveJob
[![Build Status](https://travis-ci.com/veeqo/activejob-uniqueness.svg?branch=master)](https://travis-ci.com/veeqo/activejob-uniqueness) [![Gem Version](https://badge.fury.io/rb/activejob-uniqueness.svg)](https://badge.fury.io/rb/activejob-uniqueness)

The gem allows to protect job uniqueness with next strategies:

| Strategy | The job is locked | The job is unlocked |
|-|-|-|
| `until_executing` | when **pushed** to the queue | when **processing starts** |
| `until_executed` | when **pushed** to the queue | when the job is **processed successfully** |
| `until_expired` | when **pushed** to the queue | when the lock is **expired** |
| `until_and_while_executing` | when **pushed** to the queue | when **processing starts**<br>a runtime lock is acquired to **prevent simultaneous jobs** |
| `while_executing` | when **processing starts** | when the job is **processed**<br>with any result including an error |

Inspired by [SidekiqUniqueJobs](https://github.com/mhenrixon/sidekiq-unique-jobs), uses [Redlock](https://github.com/leandromoreira/redlock-rb) under the hood, sponsored by [Veeqo](https://www.veeqo.com/).

## Installation

Add the `activejob-uniqueness` gem to your Gemfile.

```ruby
gem 'activejob-uniqueness'
```

And run `bundle install` command.

## Configuration

ActiveJob::Uniqueness is ready to work without any configuration. It will use `REDIS_URL` to connect to Redis instance.
To override the defaults, create an initializer `config/initializers/active_job_uniqueness.rb` using the following command:

```sh
rails generate active_job:uniqueness:install
```

## Usage

Define uniqueness strategy for your job via `unique` class method:

```ruby
class MyJob < ActiveJob::Base
  unique :until_executed

  # Custom expiration:
  # unique :until_executed, lock_ttl: 3.hours

  # Do not raise error on non unique jobs enqueuing:
  # unique :until_executed, on_conflict: :log

  # Handle conflict by custom Proc:
  # unique :until_executed, on_conflict: ->(job) { job.logger.info 'Oops' }

  # The :until_and_while_executing strategy supports extra attributes for a runtime lock:
  # unique :until_and_while_executing runtime_lock_ttl: 10.minutes, on_runtime_conflict: :log
end
```

ActiveJob::Uniqueness allows to manually unlock jobs:

```ruby
# Remove the lock for particular arguments:
MyJob.unlock!(foo: 'bar')
# or
ActiveJob::Uniqueness.unlock!(job_class_name: 'MyJob', arguments: [{foo: 'bar'}])

# Remove all locks of MyJob
MyJob.unlock!
# or
ActiveJob::Uniqueness.unlock!(job_class_name: 'MyJob')

# Remove all locks
ActiveJob::Uniqueness.unlock!
```

## Test mode

Most probably you don't want jobs to be locked in tests. Add this line to your test suite (`rails_helper.rb`):

```ruby
ActiveJob::Uniqueness.test_mode!
```

## Logging

ActiveJob::Uniqueness instruments `ActiveSupport::Notifications` with next events:
* `lock.active_job_uniqueness`
* `runtime_lock.active_job_uniqueness`
* `unlock.active_job_uniqueness`
* `runtime_unlock.active_job_uniqueness`
* `conflict.active_job_uniqueness`
* `runtime_conflict.active_job_uniqueness`

And then writes to `ActiveJob::Base.logger`.

### ActiveJob prior to version `6.1` will always log `Enqueued MyJob (Job ID) ...` even if the callback chain was halted. [Details](https://github.com/rails/rails/pull/37830)

## Testing

Run redis server (in separate console):
```
docker run --rm -p 6379:6379 redis
```

Run tests with:

```sh
bundle
rake
```

Use [wwtd](https://github.com/grosser/wwtd) to run test matrix:
```sh
gem install wwtd
wwtd
```

## Sidekiq adapter support

ActiveJob::Uniqueness patches Sidekiq API to unset locks on jobs cleanup. Starting Sidekiq 5.1 job death also triggers locks cleanup.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/veeqo/activejob-uniqueness.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
