# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased](https://github.com/veeqo/activejob-uniqueness/compare/v0.2.3...HEAD)

## [0.2.3](https://github.com/veeqo/activejob-uniqueness/compare/v0.2.2...v0.2.3) - 2022-02-28

### Added
- [#36](https://github.com/veeqo/activejob-uniqueness/pull/36) Support ActiveJob/Rails 7.0
- [#37](https://github.com/veeqo/activejob-uniqueness/pull/37) Add Ruby 3.1 to CI by [@petergoldstein](https://github.com/petergoldstein)

## [0.2.2](https://github.com/veeqo/activejob-uniqueness/compare/v0.2.1...v0.2.2) - 2021-10-22

### Added
- [#32](https://github.com/veeqo/activejob-uniqueness/pull/32) Add ability to set a custom runtime lock key for `:until_and_while_executing` strategy

## [0.2.1](https://github.com/veeqo/activejob-uniqueness/compare/v0.2.0...v0.2.1) - 2021-08-24

### Added
- [#30](https://github.com/veeqo/activejob-uniqueness/pull/30) Add Sidekiq::JobRecord support (reported by [@dwightwatson](https://github.com/dwightwatson))

## [0.2.0](https://github.com/veeqo/activejob-uniqueness/compare/v0.1.4...v0.2.0) - 2021-05-09

### Added
- [#22](https://github.com/veeqo/activejob-uniqueness/pull/22) Test with ruby 3.0.1

### Changed
- [#20](https://github.com/veeqo/activejob-uniqueness/pull/20) **Breaking** Sidekiq patch is not applied automatically anymore
- [#21](https://github.com/veeqo/activejob-uniqueness/pull/21) Migrate from Travis to Github Actions
- [#24](https://github.com/veeqo/activejob-uniqueness/pull/24) The default value for `retry_count` of redlock is now 0
- Require ruby 2.5+

## [0.1.4](https://github.com/veeqo/activejob-uniqueness/compare/v0.1.3...v0.1.4) - 2020-09-22

### Fixed
- [#11](https://github.com/veeqo/activejob-uniqueness/pull/11) Fix deprecation warnings for ruby 2.7 by [@DanAndreasson](https://github.com/DanAndreasson)
- [#13](https://github.com/veeqo/activejob-uniqueness/pull/13) Fix deprecation warnings for ruby 2.7

## [0.1.3](https://github.com/veeqo/activejob-uniqueness/compare/v0.1.2...v0.1.3) - 2020-08-17

### Fixed
- [#7](https://github.com/veeqo/activejob-uniqueness/pull/7) Fix deprecation warnings for ruby 2.7 by [@tonobo](https://github.com/tonobo)

### Changed
- [#8](https://github.com/veeqo/activejob-uniqueness/pull/8) Use appraisal gem to control gem versions of tests matrix
- [#9](https://github.com/veeqo/activejob-uniqueness/pull/9) Refactor of Sidekiq API patch. Fixes [#6](https://github.com/veeqo/activejob-uniqueness/issues/6) Rails boot error for version 0.1.2
- [#10](https://github.com/veeqo/activejob-uniqueness/pull/10) Refactor changelog to comply with Keep a Changelog

## [0.1.2](https://github.com/veeqo/activejob-uniqueness/compare/v0.1.1...v0.1.2) - 2020-07-30

### Added
-  [#5](https://github.com/veeqo/activejob-uniqueness/pull/5) Release lock for Sidekiq adapter by [@vbyno](https://github.com/vbyno)

## [0.1.1](https://github.com/veeqo/activejob-uniqueness/compare/v0.1.0...v0.1.1) - 2020-07-23

### Fixed
- [#4](https://github.com/veeqo/activejob-uniqueness/pull/4) Fix `NoMethodError` on `Rails.application.eager_load!` in Rails initializer

## [0.1.0](https://github.com/veeqo/activejob-uniqueness/releases/tag/v0.1.0) - 2020-07-05

### Added
- Job uniqueness for ActiveJob
