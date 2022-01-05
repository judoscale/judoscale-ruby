The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.11.0...master)

No currently unreleased changes.

## [0.11.0](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.10.2...v0.11.0)

### Added

- Add `RAILS_AUTOSCALE_MAX_QUEUES` config option. ([28738a5](https://github.com/adamlogic/rails_autoscale_agent/commit/28738a5dc4cd6b0a46e77459d6f98e6b33072da9))

## [0.10.2](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.10.1...v0.10.2) - 2021-01-12

### Changed

- Loosen Ruby constraint to allow Ruby 3. ([#36](https://github.com/adamlogic/rails_autoscale_agent/pull/36))

## [0.10.1](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.9.1...v0.10.1) - 2021-01-03

### Added

- Add support for [long-running jobs](https://railsautoscale.com/docs/long-running-jobs/) in Sidekiq and Delayed Job.
- Handle x-request-start measured in seconds (instead of milliseconds) to support nginx buildpack ([cd092f3](https://github.com/adamlogic/rails_autoscale_agent/commit/cd092f38718abf5ffaea866bcae7831d4c910ffd))
- Override worker adapter config via env var ([75dd06b](https://github.com/adamlogic/rails_autoscale_agent/commit/75dd06b2a7ff4eeab829eec24d503dc067c8fe32))

### Changed

- Require Ruby 2.5 or newer. ([b033050](https://github.com/adamlogic/rails_autoscale_agent/commit/b033050b7f9d4d7f1e50dbd780cf0e1822249268))
- Only report worker metrics from web.1 to avoid redundant data. ([d5d5fa8](https://github.com/adamlogic/rails_autoscale_agent/commit/d5d5fa87fb4d7d046832a64edde9ed0c3a6ec75f))
- Don't collect worker metrics for an unreasonable number of queues. ([a9358af](https://github.com/adamlogic/rails_autoscale_agent/commit/a9358af74a29a941d1f1d60a0222077dafd5ce08))

### Fixed

- Avoid holding onto database connections (DJ & Que only). ([3919ca5](https://github.com/adamlogic/rails_autoscale_agent/commit/3919ca54420cafa82abf9f8cd251569f9637482b))
- Better error handling for worker adapters. ([190786e](https://github.com/adamlogic/rails_autoscale_agent/commit/190786e4a910d41e394a3129aac1d23b594dbd9b))
- Don't collect metrics of the reporter isn't running. Avoids memory bloat. ([247c322](https://github.com/adamlogic/rails_autoscale_agent/commit/247c322cffc625a8c6b2395080a048ffb94e7f3b))

## [0.10.0](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.9.1...v0.10.0) - 2021-01-03 [YANKED]

_I released the wrong branch 🤦‍♂️_

## [0.9.1](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.9.0...v0.9.1) - 2020-07-29

### Fixed

- Fix a bug in error handling. ([3018542](https://github.com/adamlogic/rails_autoscale_agent/commit/3018542cd046fc4e1bd6e7da86e72a6aa2d50a8f))
- Remove unintentional Rails dependency.

## [0.9.0](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.8.3...v0.9.0) - 2020-07-12

### Added

- Add support for Resque workers.
- Add dev mode for working on the agent gem itself. ([47e3fca](https://github.com/adamlogic/rails_autoscale_agent/commit/47e3fca5b788f48567a345d9cab3a26b9cd87693))
- Report agent exceptions to Rails Autoscale.

### Changed

- Adjust queue time metric to exclude time waiting for large request bodies. ([#25](https://github.com/adamlogic/rails_autoscale_agent/pull/25))
- Que and DJ jobs without a queue name will be included in the "default" queue metrics.

### Fixed

- Multiple fixes to the Delayed Job SQL query.

## [0.8.3](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.8.2...v0.8.3) - 2020-05-26

### Fixed

- Ignored failed job in Delayed Job adapter. ([fa72fc2](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.8.2...v0.8.3))

## [0.8.2](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.8.1...v0.8.2) - 2020-05-22

### Fixed

- Ignore worker metrics from unnamed queues (DJ & Que only). These metrics were being lumped with web metrics. ([#21](https://github.com/adamlogic/rails_autoscale_agent/pull/21))

## [0.8.1](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.8.0...v0.8.1) - 2020-05-04

### Fixed

- Ignore failed jobs in Que adapter. ([#18](https://github.com/adamlogic/rails_autoscale_agent/pull/18))

## [0.8.0](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.7.0...v0.8.0) - 2020-03-21

### Added

- Add support for Delayed Job ([#14](https://github.com/adamlogic/rails_autoscale_agent/pull/14))
- Add support for Que ([#15](https://github.com/adamlogic/rails_autoscale_agent/pull/15))

## [0.7.0](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.6.3...v0.7.0) - 2019-12-04

### Added

- Make worker adapters configurable. ([012d937](https://github.com/adamlogic/rails_autoscale_agent/commit/012d9379296763f5e42df95f05b066fe82ab0051))

## [0.6.3](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.6.2...v0.6.3) - 2019-06-25

### Fixed

- Fix issues with logging.

## [0.6.2](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.6.1...v0.6.2) - 2019-06-22

### Fixed

- Fix issues with logging.

## [0.6.1](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.6.0...v0.6.1) - 2019-05-06

### Fixed

- Don't assume Sidekiq is present.

## [0.6.0](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.4.1...v0.6.0) - 2019-05-03

### Added

- Add support for autoscaling Sidekiq.
