# Rails Autoscale

[![Build Status: rails-autoscale-core](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-core-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)
[![Build Status: rails-autoscale-web](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-web-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)
[![Build Status: rails-autoscale-delayed_job](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-delayed_job-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)
[![Build Status: rails-autoscale-que](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-que-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)
[![Build Status: rails-autoscale-sidekiq](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-sidekiq-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)

These gems works together with the [Rails Autoscale](https://railsautoscale.com) Heroku add-on to scale your web and worker dynos automatically. They gather a minimal set of metrics for each request and job queue, and periodically posts this data asynchronously to the Rails Autoscale API.

## Requirements

- Rack-based app
- Ruby 2.6 or newer
- [Rails Autoscale](https://elements.heroku.com/rails-autoscale) installed on your Heroku app

## Installation

To connect your app with Rails Autoscale, add these lines to your application's `Gemfile` and run `bundle install`:

```ruby
gem "rails-autoscale-web"
# Uncomment the gem for your job backend:
# gem "rails-autoscale-sidekiq"
# gem "rails-autoscale-resque"
# gem "rails-autoscale-delayed_job"
# gem "rails-autoscale-que"
```

_If you're using a background job queue like Sidekiq or Delayed Job, make sure you include the corresponding rails-autoscale gem as well._

The adapters report queue metrics to Rails Autoscale every 10 seconds. The reporter will not run in development, or any other environment missing the `RAILS_AUTOSCALE_URL` environment variable. (This environment variable is set for you automatically when provisioning the add-on.)

## Installation for Non-Rails Rack apps

If you're using another Rack-based framework (such as Sinatra), you should use `rails-autoscale-core` instead of `rails-autoscale-web`:

```ruby
gem "rails-autoscale-core"
```

This gem provides a request middleware, but you'll need to insert that middleware in your app.

```ruby
require "rails_autoscale/request_middleware"
use RailsAutoscale::RequestMiddleware
```

If possible, insert it before `Rack::Runtime` to ensure accuracy of request queue timings.

`RailsAutoscale::RequestMiddleware` will start the reporter when it processes the first request.

## Worker adapters

Rails Autoscale will autoscale your worker dynos! Four job backends are supported: Sidekiq, Delayed Job, and Que. Be sure to install the gem specific to your job backend:

```ruby
gem "rails-autoscale-sidekiq"
gem "rails-autoscale-resque"
gem "rails-autoscale-delayed_job"
gem "rails-autoscale-que"
```

For most apps, no additional configuration is needed. See the [configuration](#configuration) section below for all available options.

## Worker-only apps

If your app doesn't have a web process, you don't _have_ to include the "rails-autoscale-web" gem. If you omit it, you'll need to start the reporter manually:

```ruby
require "rails_autoscale/reporter"
RailsAutoscale::Reporter.start
```

## What data is collected?

The reporter runs in its own thread so your web requests and background jobs are not impacted. The following data is submitted periodically to the Rails Autoscale API:

- Ruby version
- Rails version
- Job library version (for Sidekiq, etc.)
- Rails Autoscale gem versions
- Dyno name (example: web.1)
- PID
- Collection of queue time metrics (time and milliseconds)

Rails Autoscale aggregates and stores this information to power the autoscaler algorithm and dashboard visualizations.

## Migrating from `rails_autoscale_agent`

The migration from `rails_autoscale_agent` to `rails-autoscale-web` (+ your job framework gem) is typically a single step: replace the `gem "rails_autoscale_agent"` in your Gemfile with `gem "rails-autoscale-web"` _and_ the appropriate `rails-autoscale-*` package for your back-end job framework (`sidekiq`, `resque`, `delayed_job`, or `que`) or see the [Installation](#installation) section above for further specifics. If you previously had any custom configuration for the `rails_autoscale_agent`, please note that we now use a `configure` block as shown below.

Looking for the old `rails_autoscale_agent` docs? They're available on [this branch](https://github.com/rails-autoscale/rails-autoscale-gems/tree/rails_autoscale_agent).

## Migrating from `judoscale-ruby` (and `judoscale-rails`, etc.)

(Judoscale customers only) To avoid maintaining two separate sets of Ruby gems, we have deprecated the [`judoscale-ruby` gems](https://github.com/adamlogic/judoscale-ruby) in favor of `rails-autoscale-gems` (this repo). Replace `judoscale-*` with `rails-autoscale-*` in your Gemfile, and you'll be good to go!

See this article if you need help [deciding between Judoscale and Rails Autoscale](https://judoscale.com/guides/judoscale-rails-autoscale/).

## Configuration

All autoscaling configurations are handled in the Rails Autoscale web UI, but there a few ways you can change the behavior of the adapters. Most apps won't need to change any of the adapter configurations, in which case an initializer is not required.

The sample code below uses "sidekiq" for worker adapter configuration, but the options are available for each worker adapter. Replace "sidekiq" with your job backend to use those config options.

```ruby
# config/initializers/rails_autoscale.rb
RailsAutoscale.configure do |config|
  # Provide a custom logger.
  # Default: (Rails logger, if available, or a basic Logger to STDOUT)
  config.logger = MyLogger.new

  # Change the log_level for debugging or to quiet the logs.
  # See more in the "logging" section of the README.
  # Default: (defer to underlying logger)
  config.log_level = :debug

  # Interval between each metrics report to the Rails Autoscale API.
  # Default: 10 seconds
  config.report_interval_seconds = 5

  # Worker metrics will only report up to 20 queues by default. If you have more than 20 queues,
  # you'll need to configure this setting for the specific worker adapter or reduce your number of queues.
  # Default: 20 queues
  config.sidekiq.max_queues = 30

  # Specify a list of queues to collect metrics from. This overrides the default behavior which
  # automatically detects the queues. If specified, anything not explicitly listed will be excluded.
  # When setting the list of queues, `queue_filter` is ignored, but `max_queues` is still respected.
  # Default: (queues detected automatically)
  config.sidekiq.queues = %w[low default high]

  # Filter queues to collect metrics from with a custom proc.
  # Return a falsy value (`nil`/`false`) to exclude the queue, any other value will include it.
  # Default: (queues that look like a UUID are rejected)
  config.sidekiq.queue_filter = ->(queue_name) { /custom/.match?(queue_name) }

  # Enables reporting for active (busy) workers so that downscaling can be
  # suppressed.
  # See https://railsautoscale.com/docs/long-running-jobs/.
  # Default: false
  config.sidekiq.track_busy_jobs = true

  # Disable reporting for this worker adapter.
  # Default: true
  config.sidekiq.enabled = false
end
```

## Logging

`rails-autoscale-web` will use the Rails logger by default. Otherwise everything will log to STDOUT.

If you wish to use a different logger, you can set it on the configuration object:

```ruby
# config/initializers/rails_autoscale.rb
RailsAutoscale.configure do |config|
  config.logger = MyLogger.new
end
```

The underlying logger controls the log level by default. In case of Rails apps, that's going to be defined by the `log_level` config in each Rails environment. So, if your app is set to log at INFO level, you will only see Rails Autoscale INFO logs as well. Please note that this gem has _very_ chatty debug logs, so if your app is set to DEBUG you will also see a lot of logging from Rails Autoscale. Our debug logs look like this:

```
[RailsAutoscale] [DEBUG] Some debug log message
```

If you find the gem too chatty with that setup, you can quiet it down with a more strict log level that only affects Rails Autoscale logging:

```ruby
# config/initializers/rails_autoscale.rb
RailsAutoscale.configure do |config|
  config.log_level = :info
end
```

Alternatively, set the `RAILS_AUTOSCALE_LOG_LEVEL` environment variable on your Heroku app:

```
heroku config:set RAILS_AUTOSCALE_LOG_LEVEL=info
```

If that's _still_ too chatty for you, you can restrict it further:

```ruby
# config/initializers/rails_autoscale.rb
RailsAutoscale.configure do |config|
  config.log_level = :warn
end
```

## Troubleshooting

Once installed, you should see something like this in your development log:

> [RailsAutoscale] Reporter not started: RAILS_AUTOSCALE_URL is not set

On the Heroku app where you've installed the add-on, run `heroku logs -t | grep RailsAutoscale`, and you should see something like this:

> [RailsAutoscale] Reporter starting, will report every 10 seconds

If you don't see either of these, try running `bundle` again and restarting your Rails application.

You can see more detailed (debug) logging by setting `RAILS_AUTOSCALE_LOG_LEVEL` on your Heroku app:

```
heroku config:set RAILS_AUTOSCALE_LOG_LEVEL=debug
```

Reach out to help@railsautoscale.com if you run into any other problems.

## Development

After checking out the repo, run `bin/setup` to install dependencies across all the `rails-autoscale-*` libraries, or install each one individually via `bundle install`. Then, run `bin/test` to run all the tests across all the libraries, or inside each `rails-autoscale-*` library, run `bundle exec rake test`. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install each gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, commit it, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rails-autoscale/rails-autoscale-gems.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
