The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://github.com/judoscale/judoscale-ruby/compare/v0.10.2...main)

- Add busy job tracking support for Resque: ([#92](https://github.com/judoscale/judoscale-ruby/pull/92))
- Enforce and test against supported versions officially across all job adapters:
  - Sidekiq: 5, 6
  - Resque: 2
  - Que: 1
  - DJ: 4
- Prevent Que adapter from collecting metrics of jobs locked for execution. [Original issue reference](https://github.com/adamlogic/rails_autoscale_agent/issues/42) ([#85](https://github.com/judoscale/judoscale-ruby/pull/85))
- Remove the collection of a "default" queue across all job adapters. ([#84](https://github.com/judoscale/judoscale-ruby/pull/84))
- Make logging more consistent if it has been configured: ([#60](https://github.com/judoscale/judoscale-ruby/pull/60))
  - Without a configured log level, we'll just let the underlying logger (e.g. `Rails.logger` in the context of Rails) handle it.
  - With a configured log level, we:
    - skip if that level doesn't allow logging. (e.g. configured to INFO skips DEBUG logs by default)
    - let the underlying logger handle it if it allows the log level. (e.g. configured to INFO and logger has level INFO or DEBUG)
    - prefix our level to the message and use the underlying logger level if it doesn't allow ours, to ensure messages are logged. (e.g. configured to DEBUG and logger has level INFO, which wouldn't allow DEBUG messages)
- Add sample apps:
  - `judoscale-rails` ([#41](https://github.com/judoscale/judoscale-ruby/pull/41))
  - `judoscale-sidekiq` ([#56](https://github.com/judoscale/judoscale-ruby/pull/56))
  - `judoscale-resque` ([#74](https://github.com/judoscale/judoscale-ruby/pull/74))
  - `judoscale-delayed_job` ([#75](https://github.com/judoscale/judoscale-ruby/pull/75))
  - `judoscale-que` ([#76](https://github.com/judoscale/judoscale-ruby/pull/76))
- Split into multiple libraries/adapters: (including several internal refactorings & renamings to the core code to enable better separation and registration of the different libraries/adapters)
  - `judoscale-ruby` is the base Ruby library containing the core implementation used by all other libraries, and is responsible for running the metrics collection and reporting to Judoscale. ([#47](https://github.com/judoscale/judoscale-ruby/pull/47))
  - `judoscale-rails` integrates with Rails to initialize the reporter on app boot to send metrics to Judoscale, and register a middleware to collect web request metrics for reporting. ([#47](https://github.com/judoscale/judoscale-ruby/pull/47))
  - `judoscale-sidekiq` integrates with Sidekiq to collect queue metrics. ([#52](https://github.com/judoscale/judoscale-ruby/pull/52))
  - `judoscale-resque` integrates with Resque to collect queue metrics. ([#61](https://github.com/judoscale/judoscale-ruby/pull/61))
  - `judoscale-delayed_job` integrates with Delayed Job to collect queue metrics. ([#64](https://github.com/judoscale/judoscale-ruby/pull/64))
  - `judoscale-que` integrates with Que to collect queue metrics.([#65](https://github.com/judoscale/judoscale-ruby/pull/65))
- Tests no longer use VCR, requiring only Webmock. ([#53](https://github.com/judoscale/judoscale-ruby/pull/53))
- Include contextual metadata with each report, remove the registration API when starting the reporter. ([#50](https://github.com/judoscale/judoscale-ruby/pull/50))
- Report metrics using a JSON payload instead of CSV + query params. ([#42](https://github.com/judoscale/judoscale-ruby/pull/42))
- Drop `worker_adapters` config list in favor of setting it for each individual adapter `<adapter>.enabled = true|false`. This allows to manually disable reporting for any automatically enabled adapter. ([#38](https://github.com/judoscale/judoscale-ruby/issues/38))
- Combine `debug` and `quiet` config options into a single `log_level` which controls how our logging should behave. ([#37](https://github.com/judoscale/judoscale-ruby/issues/37))
- Rename some configs: `<adapter>.track_long_running_jobs` => `<adapter>.track_busy_jobs`, `report_interval` => `report_interval_seconds`, `max_request_size` => `max_request_size_bytes`. ([#36](https://github.com/judoscale/judoscale-ruby/issues/36))
- Silence queries from DelayedJob and Que adapters when collecting metrics. ([#35](https://github.com/judoscale/judoscale-ruby/pull/35))
- Allow configuring a list of `queues` to collect metrics from. Any queues not in that list will be excluded, and `queue_filter` is not applied. Please note that `max_queues` still applies. ([#33](https://github.com/judoscale/judoscale-ruby/pull/33))
- Adapter config `max_queues` to report is now 20 by default (previously 50), and will report up to that number of queues (sorted by queue name length) instead of skipping all the reporting once that threshold is crossed. ([#31](https://github.com/judoscale/judoscale-ruby/pull/31))
- Allow configuring a custom proc to filter queues to collect metrics from by name: `queue_filter = ->(queue_name) { /custom/.match?(queue_name) }`. By default it will filter out queues matching UUIDs. ([#30](https://github.com/judoscale/judoscale-ruby/pull/30))
- Allow per-adapter configuration of `max_queues` and `track_long_running_jobs`, dropping support for the global configurations. ([#29](https://github.com/judoscale/judoscale-ruby/pull/29))
- Drop support for ENV vars `JUDOSCALE_WORKER_ADAPTER`, `JUDOSCALE_LONG_JOBS`, and `JUDOSCALE_MAX_QUEUES`, in favor of using the new block config format. ([#26](https://github.com/judoscale/judoscale-ruby/pull/26))
- Configure Judoscale through a block: `Judoscale.configure { |config| config.logger = MyLogger.new }`. ([#25](https://github.com/judoscale/judoscale-ruby/pull/25))
- Remove legacy configs: `sidekiq_latency_for_active_jobs`, `latency_for_active_jobs`. ([#22](https://github.com/judoscale/judoscale-ruby/pull/22))
- Collect a new metric: network time, and expose it to the app via rack env with `judoscale.network_time`. This is currently only available with Puma, and represents the time Puma spent waiting for the request body. ([#20](https://github.com/judoscale/judoscale-ruby/pull/20))
- Change the `queue_time` rack env value exposed to the app to `judoscale.queue_time`. ([#18](https://github.com/judoscale/judoscale-ruby/pull/18))
- Drop dev mode. ([#16](https://github.com/judoscale/judoscale-ruby/pull/16))
- Remove error reporting via the API, log exceptions with full backtraces. (that are more easily searchable now.) ([#13](https://github.com/judoscale/judoscale-ruby/pull/13))
- Move test suite to minitest/spec. ([#8](https://github.com/judoscale/judoscale-ruby/pull/8))
- Apply StandardRB to the code. ([#5](https://github.com/judoscale/judoscale-ruby/pull/5))
- Require Ruby 2.6 or newer. ([#4](https://github.com/judoscale/judoscale-ruby/pull/4))
- Move the build to GitHub Actions. ([#2](https://github.com/judoscale/judoscale-ruby/pull/2))
- Rails Autoscale is now Judoscale. ([#1](https://github.com/judoscale/judoscale-ruby/pull/1))

## [0.10.2](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.10.1...v0.10.2) - 2021-01-12

### Changed

- Loosen Ruby constraint to allow Ruby 3. ([#36](https://github.com/adamlogic/rails_autoscale_agent/pull/36))

## [0.10.1](https://github.com/adamlogic/rails_autoscale_agent/compare/v0.9.1...v0.10.1) - 2021-01-03

### Added

- Add support for [long-running jobs](https://judoscale.com/docs/long-running-jobs/) in Sidekiq and Delayed Job.
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
- Report agent exceptions to Judoscale.

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
