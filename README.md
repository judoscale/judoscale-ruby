# Rails Autoscale

[![Build Status: rails-autoscale-core](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-core-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)
[![Build Status: rails-autoscale-web](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-web-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)
[![Build Status: rails-autoscale-delayed_job](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-delayed_job-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)
[![Build Status: rails-autoscale-que](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-que-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)
[![Build Status: rails-autoscale-sidekiq](https://github.com/rails-autoscale/rails-autoscale-gems/actions/workflows/rails-autoscale-sidekiq-test.yml/badge.svg)](https://github.com/rails-autoscale/rails-autoscale-gems/actions)

This gem works together with the [Rails Autoscale](https://railsautoscale.com) Heroku add-on to scale your web and worker dynos automatically. It gathers a minimal set of metrics for each request (and job queue), and periodically posts this data asynchronously to the Rails Autoscale service.

## Requirements

- Rack-based app
- Ruby 2.6 or newer

## Getting started on Rails

Add this line to your application's Gemfile and run `bundle`:

```ruby
gem 'rails-autoscale-web'
```

This inserts the Rails Autoscale Rack middleware and starts the asynchronous reporter.

The reporter will only communicate with Rails Autoscale if a `RAILS_AUTOSCALE_URL` ENV variable is present, which happens automatically on Heroku when you install the Rails Autoscale add-on. The reporter does nothing if `RAILS_AUTOSCALE_URL` is not present, such as in development or a staging app.

## Getting started for non-Rails Rack apps

You'll need to `require 'rails_autoscale/request_middleware'` and insert the `RailsAutoscale::RequestMiddleware` manually. Insert it before `Rack::Runtime` to ensure accuracy of request queue timings.

`RailsAutoscale::RequestMiddleware` will start the reporter when it processes the first request.

## What data is collected?

The reporter runs in its own thread so your web requests are not impacted. The following data is submitted periodically to the Rails Autoscale API:

- Ruby version
- Rails version
- Job library version (Sidekiq, etc.)
- Gem version
- Dyno name (example: web.1)
- PID
- Collection of queue time metrics (time and milliseconds)

Rails Autoscale aggregates and stores this information to power the autoscaling algorithm and dashboard visualizations.

## Configuration

Most Rails Autoscale configurations are handled via the settings page on your Rails Autoscale dashboard, but there a few ways you can directly change the behavior of the adapter by creating an initializer in your app like the following:

```ruby
# config/initializers/rails_autoscale.rb
RailsAutoscale.configure do |config|
  # configure Rails Autoscale here, more on each configuration option below.

  # Enables debug logging. This can also be enabled/disabled by setting `RAILS_AUTOSCALE_LOG_LEVEL=debug`.
  # See more in the [logging](#logging) section below.
  config.log_level = :debug
end
```

## Worker adapters

Rails Autoscale supports autoscaling worker dynos. Out of the box, three job backends are supported: Sidekiq, Delayed Job, and Que. You will need to install an additional gem depending on your job backend:

```ruby
gem 'rails-autoscale-sidekiq'
gem 'rails-autoscale-delayed_job'
gem 'rails-autoscale-que'
```

If you're also including `gem 'rails-autoscale-web'`, the reporter will start automatically. If you're using one of these job backends without Rails, you'll need to start the reporter manually when your application boots:

```ruby
require "rails_autoscale/reporter"
RailsAutoscale::Reporter.start
```

Each worker adapter has its own set of configurations. These configurations are all optional. (Replace "sidekiq" in the examples below for other worker adapters.)

```ruby
# config/initializers/rails_autoscale.rb
RailsAutoscale.configure do |config|
  # Worker metrics will only report up to 20 queues by default. If you have more than 20 queues,
  # you'll need to configure this setting for the specific worker adapter or reduce your number of queues.
  config.sidekiq.max_queues = 30

  # Specify a list of queues to collect metrics from. This overrides the default behavior which
  # automatically detects the queues. If specified, anything not explicitly listed will be excluded.
  # When setting the list of queues, `queue_filter` is ignored, but `max_queues` is still respected.
  config.sidekiq.queues = %w[low default high]

  # Filter queues to collect metrics from with a custom proc.
  # Return a falsy value (`nil`/`false`) to exclude the queue, any other value will include it.
  config.sidekiq.queue_filter = ->(queue_name) { /custom/.match?(queue_name) }

  # Enables reporting for active (busy) workers.
  # See [Handling Long-Running Background Jobs](https://railsautoscale.com/docs/long-running-jobs/) in the Rails Autoscale docs for more.
  config.sidekiq.track_busy_jobs = true

  # Disable reporting for this worker adapter
  config.sidekiq.enabled = false
end
```

It's also possible to write a custom worker adapter. See [these docs](https://railsautoscale.com/docs/custom-worker-adapter/) for details.

## Troubleshooting

Once installed, you should see something like this in your development log:

> [RailsAutoscale] Reporter not started: RAILS_AUTOSCALE_URL is not set

In production, run `heroku logs -t | grep RailsAutoscale`, and you should see something like this:

> [RailsAutoscale] Reporter starting, will report every 10 seconds

If you don't see either of these, try running `bundle` again and restarting your Rails application.

You can see more detailed (debug) logging by setting `RAILS_AUTOSCALE_LOG_LEVEL` on your Heroku app:

```
heroku config:set RAILS_AUTOSCALE_LOG_LEVEL=debug
```

See more in the [logging](#logging) section below.

Reach out to help@railsautoscale.com if you run into any other problems.

## Logging

The Rails logger is used by default when present, otherwise Rails Autoscale will log everything to `stdout`.
If you wish to use a different logger you can set it on the configuration object:

```ruby
# config/initializers/rails_autoscale.rb
RailsAutoscale.configure do |config|
  config.logger = MyLogger.new
end
```

The logger controls the log level by default. In case of Rails apps, that's going to be defined by the `log_level` config in each environment, so if your app is set to log at INFO level, you will only see Rails Autoscale INFO logs as well. Please note that this gem has _very_ chatty debug logs, so if your app is set to DEBUG you will also see a lot of Rails Autoscale debug logging output, which looks like this:

```
[RailsAutoscale] [DEBUG] Some debug log message
```

If you find the gem too chatty with that setup, you can quiet it down further with a more strict log level that only affects Rails Autoscale logging:

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

If you want the debug logs even if your app is not using the DEBUG level, set either the `log_level` config:

```ruby
# config/initializers/rails_autoscale.rb
RailsAutoscale.configure do |config|
  config.log_level = :debug
end
```

Or `RAILS_AUTOSCALE_LOG_LEVEL` on your app:

```
heroku config:set RAILS_AUTOSCALE_LOG_LEVEL=debug
```

Enabling the debug level will start logging everything, independently of the underlying logger level. It's recommended to enable it temporarily if you need to [troubleshoot](#troubleshooting) any issues.

## Development

After checking out the repo, run `bin/setup` to install dependencies across all the `rails-autoscale-*` libraries, or install each one individually via `bundle install`. Then, run `bin/test` to run all the tests across all the libraries, or inside each `rails-autoscale-*` library, run `bundle exec rake test`. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install each gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, commit it, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/rails-autoscale/rails-autoscale-gems.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
