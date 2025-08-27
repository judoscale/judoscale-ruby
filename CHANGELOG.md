The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.12.0](https://github.com/judoscale/judoscale-ruby/compare/v1.11.1...v1.12.0) (2025-08-26)


### Features

* Track utilization more accurately ([#248](https://github.com/judoscale/judoscale-ruby/issues/248)) ([73305a8](https://github.com/judoscale/judoscale-ruby/commit/73305a89bfbf023b99bb5fdd2469b1c523341659))


### Bug Fixes

* Sleep before running the first metrics collection ([#249](https://github.com/judoscale/judoscale-ruby/issues/249)) ([3315d24](https://github.com/judoscale/judoscale-ruby/commit/3315d24f23ca32142147fbaba0035eb7a321e6b2))

## [1.11.1](https://github.com/judoscale/judoscale-ruby/compare/v1.11.0...v1.11.1) (2025-05-08)


### Bug Fixes

* Switch to a `Rails::Engine` to fix init error with `Scout` + `Sentry` ([#245](https://github.com/judoscale/judoscale-ruby/issues/245)) ([d403357](https://github.com/judoscale/judoscale-ruby/commit/d403357737c196e0d769634611b142bb55ae1e08))

## [1.11.0](https://github.com/judoscale/judoscale-ruby/compare/v1.10.0...v1.11.0) (2025-04-24)


### Features

* Expand coverage with Ruby 3.4, Rails 7.2/8, Sidekiq 8 ([#241](https://github.com/judoscale/judoscale-ruby/issues/241)) ([664974d](https://github.com/judoscale/judoscale-ruby/commit/664974ddf482bd5129421fa0be9379f6db803fee))
* Introduce new middleware to track & collect utilization metrics ([#240](https://github.com/judoscale/judoscale-ruby/issues/240)) ([48ad428](https://github.com/judoscale/judoscale-ruby/commit/48ad4284effd9ce03f5a1f6bbfa94a2dc1b72761))
* Track app time as a new metric ([#238](https://github.com/judoscale/judoscale-ruby/issues/238)) ([bcb0e7a](https://github.com/judoscale/judoscale-ruby/commit/bcb0e7a4e596821ca0074c1390d67e07e2595007))


### Bug Fixes

* Add judoscale env var for max queues and long jobs ([#235](https://github.com/judoscale/judoscale-ruby/issues/235)) ([ad739e4](https://github.com/judoscale/judoscale-ruby/commit/ad739e4cf41e44a8e79c502afc02ffa461c5f8e1))

## [1.10.0](https://github.com/judoscale/judoscale-ruby/compare/v1.9.0...v1.10.0) (2025-02-17)


### Features

* Configure runtime container for Fly.io ([#233](https://github.com/judoscale/judoscale-ruby/issues/233)) ([0e51a87](https://github.com/judoscale/judoscale-ruby/commit/0e51a87c9e135c1d4fee6296eb204dd8d1daa4f4))

## [1.9.0](https://github.com/judoscale/judoscale-ruby/compare/v1.8.3...v1.9.0) (2025-01-15)


### Features

* Configure runtime container for Railway ([#230](https://github.com/judoscale/judoscale-ruby/issues/230)) ([bbcebf4](https://github.com/judoscale/judoscale-ruby/commit/bbcebf41aab4893d30cb1363cd609cde5bc57e9a))

## [1.8.3](https://github.com/judoscale/judoscale-ruby/compare/v1.8.2...v1.8.3) (2024-11-05)


### Bug Fixes

* Gracefully handle an invalid `log_level` ([#225](https://github.com/judoscale/judoscale-ruby/issues/225)) ([514976c](https://github.com/judoscale/judoscale-ruby/commit/514976cb17fbded317a6f959d1b316b6f8ef816f))

## [1.8.2](https://github.com/judoscale/judoscale-ruby/compare/v1.8.1...v1.8.2) (2024-10-16)


### Bug Fixes

* Allow customizing the rake task regex to avoid starting the reporter ([#220](https://github.com/judoscale/judoscale-ruby/issues/220)) ([ed6c30a](https://github.com/judoscale/judoscale-ruby/commit/ed6c30aa88e7b0bc17c38035fcbb753f102fb833))
* Skip starting Judoscale reporter on `rails runner` process ([#217](https://github.com/judoscale/judoscale-ruby/issues/217)) ([111830b](https://github.com/judoscale/judoscale-ruby/commit/111830b6617dce925a3b8f95dab2888e12e9cde5))

## [1.8.1](https://github.com/judoscale/judoscale-ruby/compare/v1.8.0...v1.8.1) (2024-09-10)


### Bug Fixes

* Mark the reporter thread as "fork safe" to avoid warnings ([#215](https://github.com/judoscale/judoscale-ruby/issues/215)) ([bf92a59](https://github.com/judoscale/judoscale-ruby/commit/bf92a599e3bf999b1a3156e491292e3e3bdb1d69)), closes [#170](https://github.com/judoscale/judoscale-ruby/issues/170)

## [1.8.0](https://github.com/judoscale/judoscale-ruby/compare/v1.7.1...v1.8.0) (2024-07-09)


### Features

* Support GoodJob v4 ([#213](https://github.com/judoscale/judoscale-ruby/issues/213)) ([1d8f75c](https://github.com/judoscale/judoscale-ruby/commit/1d8f75c3724947849776c29cfb9ac18bc566ad92))

## [1.7.1](https://github.com/judoscale/judoscale-ruby/compare/v1.7.0...v1.7.1) (2024-07-08)


### Bug Fixes

* Lock GoodJob dependency to < 4.0 ([#211](https://github.com/judoscale/judoscale-ruby/issues/211)) ([d558584](https://github.com/judoscale/judoscale-ruby/commit/d558584640ea23b0eb456d63852e29fd7fdc7ac1))
* Fix Rack version to work across multiple released versions ([dd0c08c](https://github.com/judoscale/judoscale-ruby/commit/dd0c08c79b93c67a567dae9e2be25cc16cf78174))

## [1.7.0](https://github.com/judoscale/judoscale-ruby/compare/v1.6.0...v1.7.0) (2024-05-03)


### Features

* Shoryuken adapter support ([#204](https://github.com/judoscale/judoscale-ruby/issues/204)) ([1dc6e00](https://github.com/judoscale/judoscale-ruby/commit/1dc6e003729c32178d38d9ae3aabc08f4b7c7e4b))

## [1.6.0](https://github.com/judoscale/judoscale-ruby/compare/v1.5.4...v1.6.0) (2024-04-26)


### Features

* Solid Queue Integration ([#199](https://github.com/judoscale/judoscale-ruby/issues/199)) ([30d95b9](https://github.com/judoscale/judoscale-ruby/commit/30d95b932990e2b59cb5283b692f6f3549c9b567))


### Bug Fixes

* Always send reports, even with no metrics ([e40e43f](https://github.com/judoscale/judoscale-ruby/commit/e40e43f133d591cc7e4b3fadf8a0968a9d318ff9))
* GoodJob dependency on Rails Autoscale version of the gem ([#198](https://github.com/judoscale/judoscale-ruby/issues/198)) ([adccecc](https://github.com/judoscale/judoscale-ruby/commit/adcceccb54269d3ee10e141e1a24ff7edd9c8574))

## [1.5.4](https://github.com/judoscale/judoscale-ruby/compare/v1.5.3...v1.5.4) (2024-02-07)


### Bug Fixes

* Fix deprecation warning in Sidekiq 7.2 ([9e22147](https://github.com/judoscale/judoscale-ruby/commit/9e22147343279361ff59782bd37d0dd5d666253d)), closes [#195](https://github.com/judoscale/judoscale-ruby/issues/195)

## [1.5.3](https://github.com/judoscale/judoscale-ruby/compare/v1.5.2...v1.5.3) (2024-01-25)


### Bug Fixes

* Don't include "enabled" metadata with adapters ([#193](https://github.com/judoscale/judoscale-ruby/issues/193)) ([ff6a560](https://github.com/judoscale/judoscale-ruby/commit/ff6a560ff6479f0eba8c2907bec60383bcaed2de))
* Fix console detection and improve rake detection ([#192](https://github.com/judoscale/judoscale-ruby/issues/192)) ([d6ae321](https://github.com/judoscale/judoscale-ruby/commit/d6ae32109b0793d5f36b31be07d471f1029a4a9a))
* Gracefully fail when JUDOSCALE_URL is a blank string ([ca565d3](https://github.com/judoscale/judoscale-ruby/commit/ca565d377f6aed430a57a89862262e7bf254e8d1))
* Use the configured log level even if the logger has already been initialized ([#190](https://github.com/judoscale/judoscale-ruby/issues/190)) ([7908eb2](https://github.com/judoscale/judoscale-ruby/commit/7908eb25914019b07328ee994f3763b60d4bde5b))


### Performance Improvements

* Skip reporting if there are no metrics ([#191](https://github.com/judoscale/judoscale-ruby/issues/191)) ([0835f53](https://github.com/judoscale/judoscale-ruby/commit/0835f53e615350f432be9d7e759c7ec8327cf829))

## [1.5.2](https://github.com/judoscale/judoscale-ruby/compare/v1.5.1...v1.5.2) (2023-08-10)


### Bug Fixes

* Properly handle GoodJob configured with a non-primary database ([#182](https://github.com/judoscale/judoscale-ruby/issues/182)) ([ed0c6f4](https://github.com/judoscale/judoscale-ruby/commit/ed0c6f467106260cb9f4345bd62444c4196f1919))

## [1.5.1](https://github.com/judoscale/judoscale-ruby/compare/v1.5.0...v1.5.1) (2023-08-09)


### Bug Fixes

* Don't start the reporter in build processes ([#180](https://github.com/judoscale/judoscale-ruby/issues/180)) ([0cc3b57](https://github.com/judoscale/judoscale-ruby/commit/0cc3b5791a41e3f470a782f9f190499e74585ecd))

## [1.5.0](https://github.com/judoscale/judoscale-ruby/compare/v1.4.1...v1.5.0) (2023-07-17)


### Features

* Add support for Amazon ECS services ([#179](https://github.com/judoscale/judoscale-ruby/issues/179)) ([75de436](https://github.com/judoscale/judoscale-ruby/commit/75de436aba8df94cf5542378b192d22ecdd5f61d))


### Bug Fixes

* Fail silently when DB or table is missing ([#175](https://github.com/judoscale/judoscale-ruby/issues/175)) ([4e1cab6](https://github.com/judoscale/judoscale-ruby/commit/4e1cab6b33fe1af9d6c690f0c8f23db44593f1da))

## [1.4.1](https://github.com/judoscale/judoscale-ruby/compare/v1.4.0...v1.4.1) (2023-05-04)


### Bug Fixes

* Don't start the reporter in a Rails console ([#172](https://github.com/judoscale/judoscale-ruby/issues/172)) ([c75770e](https://github.com/judoscale/judoscale-ruby/commit/c75770e1ec2bc9d0d30f3e143f41f28f8f294be7))

## [1.4.0](https://github.com/judoscale/judoscale-ruby/compare/v1.3.1...v1.4.0) (2023-04-19)


### Features

* 🤖✨ Add Render platform support ([#142](https://github.com/judoscale/judoscale-ruby/issues/142)) ([81f283e](https://github.com/judoscale/judoscale-ruby/commit/81f283eef5251974641341fcd3160c10c7955a05))
* Handle request-start header in microseconds and nanoseconds ([#157](https://github.com/judoscale/judoscale-ruby/issues/157)) ([6c91e1d](https://github.com/judoscale/judoscale-ruby/commit/6c91e1d1d182caf3e7f6aeb923d255b60e17cc2f))

## [1.3.1](https://github.com/judoscale/judoscale-ruby/compare/v1.3.0...v1.3.1) (2023-03-11)


### Bug Fixes

* Gracefully handle several types of transient TCP errors ([bbe4813](https://github.com/judoscale/judoscale-ruby/commit/bbe4813c083bf95ebe7a5a6dbb519f808ba2ab98))

## [1.3.0](https://github.com/judoscale/judoscale-ruby/compare/v1.2.3...v1.3.0) (2023-02-09)


### Features

* Add GoodJob adapter ([#116](https://github.com/judoscale/judoscale-ruby/issues/116)) ([97de556](https://github.com/judoscale/judoscale-ruby/commit/97de556ccf6996adf27cc0dc05b84828cc0c7ffb))


### Bug Fixes

* Correctly interpret x-request-start header when measured in nanoseconds ([#64](https://github.com/judoscale/judoscale-ruby/issues/64)) ([38276ce](https://github.com/judoscale/judoscale-ruby/commit/38276cec321a00371d2deba0642596752c6735ab))

## [1.2.3](https://github.com/judoscale/judoscale-ruby/compare/v1.2.2...v1.2.3) (2022-11-26)


### Bug Fixes

* Add default required files when using rails-autoscale-* gems ([#90](https://github.com/judoscale/judoscale-ruby/issues/90)) ([64c5b69](https://github.com/judoscale/judoscale-ruby/commit/64c5b69bf914370fca9c46135caa32b96a6bd49c))

## [1.2.2](https://github.com/judoscale/judoscale-ruby/compare/v1.2.1...v1.2.2) (2022-11-26) YANKED


### Bug Fixes

* Fix rails-autoscale-* gem dependencies ([#88](https://github.com/judoscale/judoscale-ruby/issues/88)) ([25132da](https://github.com/judoscale/judoscale-ruby/commit/25132da88284a44a2e894a9a9ba789878f5f78cd)), closes [#87](https://github.com/judoscale/judoscale-ruby/issues/87)

## [1.2.1](https://github.com/judoscale/rails-autoscale-gems/compare/v1.2.0...v1.2.1) (2022-11-23) YANKED


### Bug Fixes

* Fix gemspecs for dual-publishing ([#81](https://github.com/judoscale/rails-autoscale-gems/issues/81)) ([a557e26](https://github.com/judoscale/rails-autoscale-gems/commit/a557e26285c43133a38eb98d5c589e413223b30a) and [#83](https://github.com/judoscale/rails-autoscale-gems/issues/83)) ([fbb2092](https://github.com/judoscale/rails-autoscale-gems/commit/fbb2092b3a8936b7d3c995df3ffe2fb54e6c3e0d))

## [1.2.0](https://github.com/judoscale/rails-autoscale-gems/compare/v1.1.1...v1.2.0) (2022-11-23) YANKED


### Features

* Rename folders, files, and constants from Rails Autoscale to Judoscale ([#79](https://github.com/judoscale/rails-autoscale-gems/issues/79)) ([061636e](https://github.com/judoscale/rails-autoscale-gems/commit/061636e0cc1fa917eed47a60a057d0d63c6f9679))

## [1.1.1](https://github.com/judoscale/judoscale-ruby/compare/v1.1.0...v1.1.1) (2022-11-14)

### Bug Fixes

- Fix "busy jobs" metric for Sidekiq 7 ([#75](https://github.com/judoscale/judoscale-ruby/issues/75)) ([aa609af](https://github.com/judoscale/judoscale-ruby/commit/aa609af93eb41cb7e231026d7948f97f55f3dc10))

## [1.1.0](https://github.com/judoscale/judoscale-ruby/compare/v1.0.3...v1.1.0) (2022-10-10)

### Features

- Add judoscale-rack gem for Rack apps (non-Rails) ([66cb51d](https://github.com/judoscale/judoscale-ruby/commit/66cb51dc871c54c58c89c4ce0b36482de99f4afb))

### Bug Fixes

- Fix logger when using Log4r ([1c9d726](https://github.com/judoscale/judoscale-ruby/commit/1c9d72655ae236fb49572fecc1209f1a7564ba0c))

## [1.0.3](https://github.com/judoscale/judoscale-ruby/compare/v1.0.2...v1.0.3) (2022-10-01)

### Bug Fixes

- Fix find & replace mistake for queue time header ([a19982d](https://github.com/judoscale/judoscale-ruby/commit/a19982d7a08f7c6ce74ff7f8e61ea689b8c2552c))

## [1.0.2](https://github.com/judoscale/judoscale-ruby/compare/v1.0.1...v1.0.2) (2022-09-26)

### Bug Fixes

- Bring back support for legacy env var configs (RAILS_AUTOSCALE_MAX_QUEUES and RAILS_AUTOSCALE_LONG_JOBS) ([c508544](https://github.com/judoscale/judoscale-ruby/commit/c508544499cfa7973c689a156722bfc9dd95418a))

## [1.0.1](https://github.com/judoscale/judoscale-ruby/compare/v1.0.0...v1.0.1) (2022-09-14)

### Bug Fixes

- Gracefully handle TCP connection timeouts ([a34797b](https://github.com/judoscale/judoscale-ruby/commit/a34797bf3cfcfefa17b8147475be26e4453aab58))

## [1.0.0](https://github.com/judoscale/judoscale-ruby/compare/v0.10.2...v1.0.0)

- Update API endpoint to V3.
- Make judoscale-ruby work with either Judoscale or Rails Autoscale
  - `Judoscale.configure` and `RailsAutoscale.configure` are both supported.
  - `RAILS_AUTOSCALE_URL` and `JUDOSCALE_URL` env vars are both supported.
- Backport all changes from judoscale-ruby to rails-autoscale-gems.
- Refactor how the config is exposed and accessed from job adapters / collectors to simplify and remove some indirection. ([#99](https://github.com/rails-autoscale/judoscale-ruby/pull/99))
- Add busy job tracking support for Que: ([#97](https://github.com/rails-autoscale/judoscale-ruby/pull/97))
- Add queue latency support to Resque via an extension, since it doesn't support it natively. ([#100](https://github.com/rails-autoscale/judoscale-ruby/pull/100))
- Add busy job tracking support for Resque: ([#92](https://github.com/rails-autoscale/judoscale-ruby/pull/92))
- Enforce and test against supported versions officially across all job adapters:
  - Sidekiq: 5, 6
  - Resque: 2
  - Que: 1
  - DJ: 4
- Prevent Que adapter from collecting metrics of jobs locked for execution. [Original issue reference](https://github.com/rails-autoscale/rails_autoscale_agent/issues/42) ([#85](https://github.com/judoscale/judoscale-ruby/pull/85))
- Remove the collection of a "default" queue across all job adapters. ([#84](https://github.com/rails-autoscale/judoscale-ruby/pull/84))
- Make logging more consistent if it has been configured: ([#60](https://github.com/rails-autoscale/judoscale-ruby/pull/60))
  - Without a configured log level, we'll just let the underlying logger (e.g. `Rails.logger` in the context of Rails) handle it.
  - With a configured log level, we:
    - skip if that level doesn't allow logging. (e.g. configured to INFO skips DEBUG logs by default)
    - let the underlying logger handle it if it allows the log level. (e.g. configured to INFO and logger has level INFO or DEBUG)
    - prefix our level to the message and use the underlying logger level if it doesn't allow ours, to ensure messages are logged. (e.g. configured to DEBUG and logger has level INFO, which wouldn't allow DEBUG messages)
- Add sample apps:
  - `judoscale-rails` ([#41](https://github.com/rails-autoscale/judoscale-ruby/pull/41))
  - `judoscale-sidekiq` ([#56](https://github.com/rails-autoscale/judoscale-ruby/pull/56))
  - `judoscale-resque` ([#74](https://github.com/rails-autoscale/judoscale-ruby/pull/74))
  - `judoscale-delayed_job` ([#75](https://github.com/rails-autoscale/judoscale-ruby/pull/75))
  - `judoscale-que` ([#76](https://github.com/rails-autoscale/judoscale-ruby/pull/76))
- Split into multiple libraries/adapters: (including several internal refactorings & renamings to the core code to enable better separation and registration of the different libraries/adapters)
  - `judoscale-ruby` is the base Ruby library containing the core implementation used by all other libraries, and is responsible for running the metrics collection and reporting to Judoscale. ([#47](https://github.com/judoscale/judoscale-ruby/pull/47))
  - `judoscale-rails` integrates with Rails to initialize the reporter on app boot to send metrics to Judoscale, and register a middleware to collect web request metrics for reporting. ([#47](https://github.com/judoscale/judoscale-ruby/pull/47))
  - `judoscale-sidekiq` integrates with Sidekiq to collect queue metrics. ([#52](https://github.com/rails-autoscale/judoscale-ruby/pull/52))
  - `judoscale-resque` integrates with Resque to collect queue metrics. ([#61](https://github.com/rails-autoscale/judoscale-ruby/pull/61))
  - `judoscale-delayed_job` integrates with Delayed Job to collect queue metrics. ([#64](https://github.com/rails-autoscale/judoscale-ruby/pull/64))
  - `judoscale-que` integrates with Que to collect queue metrics.([#65](https://github.com/rails-autoscale/judoscale-ruby/pull/65))
- Tests no longer use VCR, requiring only Webmock. ([#53](https://github.com/rails-autoscale/judoscale-ruby/pull/53))
- Include contextual metadata with each report, remove the registration API when starting the reporter. ([#50](https://github.com/rails-autoscale/judoscale-ruby/pull/50))
- Report metrics using a JSON payload instead of CSV + query params. ([#42](https://github.com/rails-autoscale/judoscale-ruby/pull/42))
- Drop `worker_adapters` config list in favor of setting it for each individual adapter `<adapter>.enabled = true|false`. This allows to manually disable reporting for any automatically enabled adapter. ([#38](https://github.com/judoscale/judoscale-ruby/issues/38))
- Combine `debug` and `quiet` config options into a single `log_level` which controls how our logging should behave. ([#37](https://github.com/rails-autoscale/judoscale-ruby/issues/37))
- Rename some configs: `<adapter>.track_long_running_jobs` => `<adapter>.track_busy_jobs`, `report_interval` => `report_interval_seconds`, `max_request_size` => `max_request_size_bytes`. ([#36](https://github.com/judoscale/judoscale-ruby/issues/36))
- Silence queries from DelayedJob and Que adapters when collecting metrics. ([#35](https://github.com/rails-autoscale/judoscale-ruby/pull/35))
- Allow configuring a list of `queues` to collect metrics from. Any queues not in that list will be excluded, and `queue_filter` is not applied. Please note that `max_queues` still applies. ([#33](https://github.com/judoscale/judoscale-ruby/pull/33))
- Adapter config `max_queues` to report is now 20 by default (previously 50), and will report up to that number of queues (sorted by queue name length) instead of skipping all the reporting once that threshold is crossed. ([#31](https://github.com/judoscale/judoscale-ruby/pull/31))
- Allow configuring a custom proc to filter queues to collect metrics from by name: `queue_filter = ->(queue_name) { /custom/.match?(queue_name) }`. By default it will filter out queues matching UUIDs. ([#30](https://github.com/judoscale/judoscale-ruby/pull/30))
- Allow per-adapter configuration of `max_queues` and `track_long_running_jobs`, dropping support for the global configurations. ([#29](https://github.com/rails-autoscale/judoscale-ruby/pull/29))
- Drop support for ENV vars `RAILS_AUTOSCALE_WORKER_ADAPTER`, `RAILS_AUTOSCALE_LONG_JOBS`, and `RAILS_AUTOSCALE_MAX_QUEUES`, in favor of using the new block config format. ([#26](https://github.com/judoscale/judoscale-ruby/pull/26))
- Configure Judoscale through a block: `Judoscale.configure { |config| config.logger = MyLogger.new }`. ([#25](https://github.com/rails-autoscale/judoscale-ruby/pull/25))
- Remove legacy configs: `sidekiq_latency_for_active_jobs`, `latency_for_active_jobs`. ([#22](https://github.com/rails-autoscale/judoscale-ruby/pull/22))
- Collect a new metric: network time, and expose it to the app via rack env with `judoscale.network_time`. This is currently only available with Puma, and represents the time Puma spent waiting for the request body. ([#20](https://github.com/judoscale/judoscale-ruby/pull/20))
- Change the `queue_time` rack env value exposed to the app to `Judoscale.queue_time`. ([#18](https://github.com/rails-autoscale/judoscale-ruby/pull/18))
- Drop dev mode. ([#16](https://github.com/rails-autoscale/judoscale-ruby/pull/16))
- Remove error reporting via the API, log exceptions with full backtraces. (that are more easily searchable now.) ([#13](https://github.com/rails-autoscale/judoscale-ruby/pull/13))
- Move test suite to minitest/spec. ([#8](https://github.com/rails-autoscale/judoscale-ruby/pull/8))
- Apply StandardRB to the code. ([#5](https://github.com/rails-autoscale/judoscale-ruby/pull/5))
- Require Ruby 2.6 or newer. ([#4](https://github.com/rails-autoscale/judoscale-ruby/pull/4))
- Move the build to GitHub Actions. ([#2](https://github.com/rails-autoscale/judoscale-ruby/pull/2))

## [0.11.0](https://github.com/judoscale/judoscale-ruby/compare/v0.10.2...v0.11.0)

### Added

- Add `RAILS_AUTOSCALE_MAX_QUEUES` config option. ([28738a5](https://github.com/judoscale/judoscale-ruby/commit/28738a5dc4cd6b0a46e77459d6f98e6b33072da9))

## [0.10.2](https://github.com/judoscale/judoscale-ruby/compare/v0.10.1...v0.10.2) - 2021-01-12

### Changed

- Loosen Ruby constraint to allow Ruby 3. ([#36](https://github.com/judoscale/judoscale-ruby/pull/36))

## [0.10.1](https://github.com/judoscale/judoscale-ruby/compare/v0.9.1...v0.10.1) - 2021-01-03

### Added

- Add support for [long-running jobs](https://judoscale.com/docs/long-running-jobs/) in Sidekiq and Delayed Job.
- Handle x-request-start measured in seconds (instead of milliseconds) to support nginx buildpack ([cd092f3](https://github.com/judoscale/judoscale-ruby/commit/cd092f38718abf5ffaea866bcae7831d4c910ffd))
- Override worker adapter config via env var ([75dd06b](https://github.com/judoscale/judoscale-ruby/commit/75dd06b2a7ff4eeab829eec24d503dc067c8fe32))

### Changed

- Require Ruby 2.5 or newer. ([b033050](https://github.com/judoscale/judoscale-ruby/commit/b033050b7f9d4d7f1e50dbd780cf0e1822249268))
- Only report worker metrics from web.1 to avoid redundant data. ([d5d5fa8](https://github.com/judoscale/judoscale-ruby/commit/d5d5fa87fb4d7d046832a64edde9ed0c3a6ec75f))
- Don't collect worker metrics for an unreasonable number of queues. ([a9358af](https://github.com/judoscale/judoscale-ruby/commit/a9358af74a29a941d1f1d60a0222077dafd5ce08))

### Fixed

- Avoid holding onto database connections (DJ & Que only). ([3919ca5](https://github.com/judoscale/judoscale-ruby/commit/3919ca54420cafa82abf9f8cd251569f9637482b))
- Better error handling for worker adapters. ([190786e](https://github.com/judoscale/judoscale-ruby/commit/190786e4a910d41e394a3129aac1d23b594dbd9b))
- Don't collect metrics of the reporter isn't running. Avoids memory bloat. ([247c322](https://github.com/judoscale/judoscale-ruby/commit/247c322cffc625a8c6b2395080a048ffb94e7f3b))

## [0.10.0](https://github.com/judoscale/judoscale-ruby/compare/v0.9.1...v0.10.0) - 2021-01-03 [YANKED]

_I released the wrong branch 🤦‍♂️_

## [0.9.1](https://github.com/judoscale/judoscale-ruby/compare/v0.9.0...v0.9.1) - 2020-07-29

### Fixed

- Fix a bug in error handling. ([3018542](https://github.com/judoscale/judoscale-ruby/commit/3018542cd046fc4e1bd6e7da86e72a6aa2d50a8f))
- Remove unintentional Rails dependency.

## [0.9.0](https://github.com/judoscale/judoscale-ruby/compare/v0.8.3...v0.9.0) - 2020-07-12

### Added

- Add support for Resque workers.
- Add dev mode for working on the agent gem itself. ([47e3fca](https://github.com/judoscale/judoscale-ruby/commit/47e3fca5b788f48567a345d9cab3a26b9cd87693))
- Report agent exceptions to Judoscale.

### Changed

- Adjust queue time metric to exclude time waiting for large request bodies. ([#25](https://github.com/judoscale/judoscale-ruby/pull/25))
- Que and DJ jobs without a queue name will be included in the "default" queue metrics.

### Fixed

- Multiple fixes to the Delayed Job SQL query.

## [0.8.3](https://github.com/judoscale/judoscale-ruby/compare/v0.8.2...v0.8.3) - 2020-05-26

### Fixed

- Ignored failed job in Delayed Job adapter. ([fa72fc2](https://github.com/judoscale/judoscale-ruby/compare/v0.8.2...v0.8.3))

## [0.8.2](https://github.com/judoscale/judoscale-ruby/compare/v0.8.1...v0.8.2) - 2020-05-22

### Fixed

- Ignore worker metrics from unnamed queues (DJ & Que only). These metrics were being lumped with web metrics. ([#21](https://github.com/judoscale/judoscale-ruby/pull/21))

## [0.8.1](https://github.com/judoscale/judoscale-ruby/compare/v0.8.0...v0.8.1) - 2020-05-04

### Fixed

- Ignore failed jobs in Que adapter. ([#18](https://github.com/judoscale/judoscale-ruby/pull/18))

## [0.8.0](https://github.com/judoscale/judoscale-ruby/compare/v0.7.0...v0.8.0) - 2020-03-21

### Added

- Add support for Delayed Job ([#14](https://github.com/judoscale/judoscale-ruby/pull/14))
- Add support for Que ([#15](https://github.com/judoscale/judoscale-ruby/pull/15))

## [0.7.0](https://github.com/judoscale/judoscale-ruby/compare/v0.6.3...v0.7.0) - 2019-12-04

### Added

- Make worker adapters configurable. ([012d937](https://github.com/judoscale/judoscale-ruby/commit/012d9379296763f5e42df95f05b066fe82ab0051))

## [0.6.3](https://github.com/judoscale/judoscale-ruby/compare/v0.6.2...v0.6.3) - 2019-06-25

### Fixed

- Fix issues with logging.

## [0.6.2](https://github.com/judoscale/judoscale-ruby/compare/v0.6.1...v0.6.2) - 2019-06-22

### Fixed

- Fix issues with logging.

## [0.6.1](https://github.com/judoscale/judoscale-ruby/compare/v0.6.0...v0.6.1) - 2019-05-06

### Fixed

- Don't assume Sidekiq is present.

## [0.6.0](https://github.com/judoscale/judoscale-ruby/compare/v0.4.1...v0.6.0) - 2019-05-03

### Added

- Add support for autoscaling Sidekiq.
