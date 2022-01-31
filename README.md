# Judoscale

[![Build Status](https://github.com/judoscale/judoscale-ruby/actions/workflows/test.yml/badge.svg)](https://github.com/judoscale/judoscale-ruby/actions)

This gem works together with the [Judoscale](https://judoscale.com) Heroku add-on to automatically scale your web and worker dynos as needed. It gathers a minimal set of metrics for each request (and job queue), and periodically posts this data asynchronously to the Judoscale service.

## Requirements

- Rack-based app
- Ruby 2.6 or newer

## Getting Started

Add this line to your application's Gemfile and run `bundle`:

```ruby
gem 'judoscale'
```

This inserts the agent into your Rack middleware stack.

The agent will only communicate with Judoscale if a `JUDOSCALE_URL` ENV variable is present, which happens automatically when you install the Heroku add-on. The middleware does nothing if `JUDOSCALE_URL` is not present, such as in development or a staging app.

## Non-Rails Rack apps

You'll need to `require 'judoscale/middleware'` and insert the `Judoscale::Middleware` manually. Insert it before `Rack::Runtime` to ensure accuracy of request queue timings.

## What data is collected?

The middleware agent runs in its own thread so your web requests are not impacted. The following data is submitted periodically to the Judoscale API:

- Ruby version
- Rails version
- Gem version
- Dyno name (example: web.1)
- PID
- Collection of queue time measurements (time and milliseconds)

Judoscale aggregates and stores this information to power the autoscaling algorithm and dashboard visualizations.

## Configuration

Most Judoscale configurations are handled via the settings page on your Judoscale dashboard, but there a few ways you can directly change the behavior of the agent via environment variables:

- `JUDOSCALE_DEBUG` - Enables debug logging. See more in the [logging](#logging) section below.
- `JUDOSCALE_WORKER_ADAPTER` - Overrides the available worker adapters. See more in the [worker adapters](#worker-adapters) section below.
- `JUDOSCALE_LONG_JOBS` - Enables reporting for active workers. See [Handling Long-Running Background Jobs](https://judoscale.com/docs/long-running-jobs/) in the Judoscale docs for more.
- `JUDOSCALE_MAX_QUEUES` - Worker metrics will only report up to 50 queues by default. If you have more than 50 queues, you'll need to configure this settings or reduce your number of queues.

## Worker adapters

Judoscale supports autoscaling worker dynos. Out of the box, four job backends are supported: Sidekiq, Resque, Delayed Job, and Que. The agent will automatically enable the appropriate worker adapter based on what you have installed in your app.

In some scenarios you might want to override this behavior. Let's say you have both Sidekiq and Resque installed 🤷‍♂️, but you only want Judoscale to collect metrics for Sidekiq. Here's how you'd override that:

```
heroku config:add JUDOSCALE_WORKER_ADAPTER=sidekiq
```

You can also disable collection of worker metrics altogether:

```
heroku config:add JUDOSCALE_WORKER_ADAPTER=""
```

It's also possible to write a custom worker adapter. See [these docs](https://judoscale.com/docs/custom-worker-adapter/) for details.

## Troubleshooting

Once installed, you should see something like this in your development log:

> [Judoscale] Reporter not started: JUDOSCALE_URL is not set

In production, run `heroku logs -t | grep Judoscale`, and you should see something like this:

> [Judoscale] Reporter starting, will report every 15 seconds

If you don't see either of these, try running `bundle` again and restarting your Rails application.

You can see more detailed (debug) logging by setting `JUDOSCALE_DEBUG` on your Heroku app:

```
heroku config:add JUDOSCALE_DEBUG=true
```

See more in the [logging](#logging) section below.

Reach out to help@judoscale.com if you run into any other problems.

## Logging

The Rails logger is used by default.
If you wish to use a different logger you can set it on the configuration object:

```ruby
# config/initializers/judoscale.rb
Judoscale.configure do |config|
  config.logger = MyLogger.new
end
```

Debug logs are silenced by default because Rails apps default to a DEBUG log level in production, and this gem has _very_ chatty debug logs. If you want to see the debug logs, set `JUDOSCALE_DEBUG` on your Heroku app:

```
heroku config:add JUDOSCALE_DEBUG=true
```

If you find the gem too chatty even without this, you can quiet it down further:

```ruby
# config/initializers/judoscale.rb
Judoscale.configure do |config|
  config.quiet = true
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, commit it, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/judoscale/judoscale-ruby.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
