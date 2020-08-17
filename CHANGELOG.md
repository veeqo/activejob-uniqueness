## Changes Between 0.1.2 and 0.1.3 (unreleased)

Fix deprecation warnings for ruby 2.7
[PR](https://github.com/veeqo/activejob-uniqueness/pull/7) by @tonobo

Use appraisal gem to control gem versions of tests matrix
[PR](https://github.com/veeqo/activejob-uniqueness/pull/8) by @sharshenov

Refactor jobs unlock by Sidekiq API (fixes NoMethodError on rails/rake commands in 0.1.2)
[PR](https://github.com/veeqo/activejob-uniqueness/pull/9) by @sharshenov

## Changes Between 0.1.1 and 0.1.2

Release lock for Sidekiq adapter when all Sidekiq attempts were unsuccessful or job is deleted manually from Sidekiq::Web
[PR](https://github.com/veeqo/activejob-uniqueness/pull/5) by @vbyno

## Changes Between 0.1.0 and 0.1.1

Fixed NoMethodError on `Rails.application.eager_load!` in Rails initializer
```
NoMethodError: undefined method `unique' for MyJob:Class
```
[PR](https://github.com/veeqo/activejob-uniqueness/pull/4)

## Original Release: 0.1.0
