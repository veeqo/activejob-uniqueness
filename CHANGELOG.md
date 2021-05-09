# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased](https://github.com/veeqo/activejob-uniqueness/compare/v0.1.4...HEAD)

### Changed
- [#21](https://github.com/veeqo/activejob-uniqueness/pull/21) Migrate from Travis to Github Actions

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
