# Judoscale

[![Build Status: judoscale-ruby](https://github.com/judoscale/judoscale-ruby/actions/workflows/judoscale-ruby-test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)
[![Build Status: judoscale-rails](https://github.com/judoscale/judoscale-ruby/actions/workflows/judoscale-rails-test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)
[![Build Status: judoscale-sidekiq](https://github.com/judoscale/judoscale-ruby/actions/workflows/judoscale-sidekiq-test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)
[![Build Status: judoscale-solid_queue](https://github.com/judoscale/judoscale-ruby/actions/workflows/judoscale-solid_queue-test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)
[![Build Status: judoscale-delayed_job](https://github.com/judoscale/judoscale-ruby/actions/workflows/judoscale-delayed_job-test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)
[![Build Status: judoscale-good_job](https://github.com/judoscale/judoscale-ruby/actions/workflows/judoscale-good_job-test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)
[![Build Status: judoscale-que](https://github.com/judoscale/judoscale-ruby/actions/workflows/judoscale-que-test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)
[![Build Status: judoscale-shoryuken](https://github.com/judoscale/judoscale-ruby/actions/workflows/judoscale-shoryuken-test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)

These gems works together with the [Judoscale](https://judoscale.com) Heroku add-on to scale your web and worker dynos automatically. They gather a minimal set of metrics for each request and job queue, and periodically posts this data asynchronously to the Judoscale API.

## Requirements

- Rack-based app
- Ruby 2.6 or newer
- [Judoscale](https://elements.heroku.com/addons/judoscale) or [Rails Autoscale](https://elements.heroku.com/addons/rails-autoscale) installed on your Heroku app

## Installation

To connect your app with Judoscale, add these lines to your application's `Gemfile` and run `bundle install`:

```ruby
gem "judoscale-rails"
# Uncomment the gem for your job backend:
# gem "judoscale-sidekiq"
# gem "judoscale-solid_queue"
# gem "judoscale-resque"
# gem "judoscale-delayed_job"
# gem "judoscale-good_job"
# gem "judoscale-que"
# gem "judoscale-shoryuken"
```

_If you're using a background job queue, make sure you include the corresponding judoscale-\* gem as well._

The adapters report queue metrics to Judoscale every 10 seconds. The reporter will not run in development, or any other environment missing the `JUDOSCALE_URL` environment variable. (This environment variable is set for you automatically when provisioning the add-on.)

## Installation for Non-Rails Rack apps

If you're using another Rack-based framework (such as Sinatra), you should use `judoscale-rack` instead of `judoscale-rails`:

```ruby
gem "judoscale-rack"
```

The gem provides a request middleware, but you'll need to insert that middleware into your app.

```ruby
Bundler.require
use Judoscale::RequestMiddleware
```

The middleware will start the async reporter when it processes the first request.

## Worker adapters

Judoscale will autoscale your worker dynos! The following job backends are supported: Sidekiq, Solid Queue, Resque, Delayed Job, Good Job, Que, and Shoryuken. Be sure to install the gem specific to your job backend:

```ruby
gem "judoscale-sidekiq"
gem "judoscale-solid_queue"
gem "judoscale-resque"
gem "judoscale-delayed_job"
gem "judoscale-good_job"
gem "judoscale-que"
gem "judoscale-shoryuken"
```

For most apps, no additional configuration is needed. See the [configuration](#configuration) section below for all available options.

Note that if you aren't using Rails, you'll need to start the reporter manually. See below.

### Specific worker backend notes

#### Resque

If you're using `resque-scheduler` and their [standalone executable](https://github.com/resque/resque-scheduler?tab=readme-ov-file#standalone-executable) approach, add a `require "judoscale-resque"` to your executable, or require your entire Rails application. This ensures the Judoscale extension that stores latency for each job gets properly loaded within the scheduler process, otherwise metrics may not be reported appropriately from the scheduler.

## Worker-only apps

If your app doesn't have a web process, you don't _have_ to include the "judoscale-rails" gem. If you omit it, you'll need to start the reporter manually:

```ruby
require "judoscale/reporter"
Judoscale::Reporter.start
```

You should do this _after_ you've configured your job backend (such as `Sidekiq.configure_server`).

## What data is collected?

The reporter runs in its own thread so your web requests and background jobs are not impacted. The following data is submitted periodically to the Judoscale API:

- Ruby version
- Rails version
- Job library version (for Sidekiq, etc.)
- Judoscale gem versions
- Dyno name (example: web.1)
- PID
- Collection of queue time and utilization metrics for web
- Collection of queue time and/or queue depth metrics, and busy metrics (if enabled), for workers (see below)

Judoscale aggregates and stores this information to power the autoscaler algorithm and dashboard visualizations.

### What data is collected for each worker adapter?

| adapter               | queue time | queue depth | busy (if enabled) |
| --------------------- | ---------- | ----------- | ----------------- |
| judoscale-sidekiq     | ✅         | ✅          | ✅                |
| judoscale-solid_queue | ✅         | ❌          | ✅                |
| judoscale-resque      | ✅         | ✅          | ✅                |
| judoscale-delayed_job | ✅         | ❌          | ✅                |
| judoscale-good_job    | ✅         | ❌          | ✅                |
| judoscale-que         | ✅         | ❌          | ✅                |
| judoscale-shoryuken   | ❌         | ✅          | ❌                |

## Migrating from `rails_autoscale_agent`

The migration from `rails_autoscale_agent` to `judoscale-rails` (+ your job framework gem) is typically a single step: replace the `gem "rails_autoscale_agent"` in your Gemfile with `gem "judoscale-rails"` _and_ the appropriate `judoscale-*` package for your back-end job framework (`sidekiq`, `resque`, `delayed_job`, `good_job`, or `que`) or see the [Installation](#installation) section above for further specifics. If you previously had any custom configuration for the `rails_autoscale_agent`, please note that we now use a `configure` block as shown below.

Looking for the old `rails_autoscale_agent` docs? They're available on [this branch](https://github.com/judoscale/judoscale-ruby/tree/rails_autoscale_agent).

## Optional Configuration

All autoscaling configurations are handled in the Judoscale web UI, but there a few ways you can change the behavior of the adapters. Most apps won't need to change any of the adapter configurations, in which case an initializer is not required.

The sample code below uses "sidekiq" for worker adapter configuration, but the options are available for each worker adapter. Replace "sidekiq" with your job backend to use those config options.

```ruby
# config/initializers/judoscale.rb
Judoscale.configure do |config|
  # Provide a custom logger.
  # Default: (Rails logger, if available, or a basic Logger to STDOUT)
  # config.logger = MyLogger.new

  # Change the log_level for debugging or to quiet the logs.
  # See more in the "logging" section of the README.
  # Default: (defer to underlying logger)
  # config.log_level = :debug

  # Interval between each metrics report to the Judoscale API.
  # Default: 10 seconds
  # config.report_interval_seconds = 5

  # Worker metrics will only report up to 20 queues by default. If you have more than 20 queues,
  # you'll need to configure this setting for the specific worker adapter or reduce your number of queues.
  # Default: 20 queues
  # config.sidekiq.max_queues = 30

  # Specify a list of queues to collect metrics from. This overrides the default behavior which
  # automatically detects the queues. If specified, anything not explicitly listed will be excluded.
  # When setting the list of queues, `queue_filter` is ignored, but `max_queues` is still respected.
  # Note: judoscale-shoryuken will only report all queues across all available processes if the list
  # of queues is specified, otherwise just the shoryuken processes can report their known queues.
  # Default: (queues detected automatically)
  # config.sidekiq.queues = %w[low default high]

  # Filter queues to collect metrics from with a custom proc.
  # Return a falsy value (`nil`/`false`) to exclude the queue, any other value will include it.
  # Default: (queues that look like a UUID are rejected)
  # config.sidekiq.queue_filter = ->(queue_name) { /custom/.match?(queue_name) }

  # Enables reporting for active (busy) workers so that downscaling can be
  # suppressed.
  # See https://judoscale.com/docs/long-running-jobs/.
  # Note: judoscale-shoryuken does not support reporting busy jobs.
  # Default: false
  # config.sidekiq.track_busy_jobs = true

  # Disable reporting for this worker adapter.
  # Default: true
  # config.sidekiq.enabled = !ENV.key?("DISABLE_JUDOSCALE_SIDEKIQ_REPORTING")
end
```

## Logging

`judoscale-rails` will use the Rails logger by default. Otherwise everything will log to STDOUT.

If you wish to use a different logger, you can set it on the configuration object:

```ruby
# config/initializers/judoscale.rb
Judoscale.configure do |config|
  config.logger = MyLogger.new
end
```

The underlying logger controls the log level by default. In case of Rails apps, that's going to be defined by the `log_level` config in each Rails environment. So, if your app is set to log at INFO level, you will only see Judoscale INFO logs as well. Please note that this gem has _very_ chatty debug logs, so if your app is set to DEBUG you will also see a lot of logging from Judoscale. Our debug logs look like this:

```
[Judoscale] [DEBUG] Some debug log message
```

If you find the gem too chatty with that setup, you can quiet it down with a more strict log level that only affects Judoscale logging:

```ruby
# config/initializers/judoscale.rb
Judoscale.configure do |config|
  config.log_level = :info
end
```

Alternatively, set the `JUDOSCALE_LOG_LEVEL` environment variable on your Heroku app:

```
heroku config:set JUDOSCALE_LOG_LEVEL=info
```

If that's _still_ too chatty for you, you can restrict it further:

```ruby
# config/initializers/judoscale.rb
Judoscale.configure do |config|
  config.log_level = :warn
end
```

## Troubleshooting

Once installed, you should see something like this in your development log:

> [Judoscale] Reporter not started: JUDOSCALE_URL is not set

On the Heroku app where you've installed the add-on, run `heroku logs -t | grep Judoscale`, and you should see something like this:

> [Judoscale] Reporter starting, will report every 10 seconds

If you don't see either of these, try running `bundle` again and restarting your Rails application.

You can see more detailed (debug) logging by setting `JUDOSCALE_LOG_LEVEL` on your Heroku app:

```
heroku config:set JUDOSCALE_LOG_LEVEL=debug
```

Reach out to help@judoscale.com if you run into any other problems.

## Development

Run `bin/test` to run all the tests across all the libraries, or inside each `judoscale-*` library, run `bundle exec rake test`. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install each gem onto your local machine, run `bundle exec rake install`.

To release a new version:

1. Use [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/#summary), and release branches will be created automatically via [Release Please](https://github.com/google-github-actions/release-please-action). This updates the changelog and the version of judoscale-ruby.
1. Merge the release branch, and GitHub Actions will run `bin/release` to publish all gems to [Rubygems](https://rubygems.org).

_Note: We keep all gem versions in sync to provide a better developer experience for our users._

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/judoscale/judoscale-ruby.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
