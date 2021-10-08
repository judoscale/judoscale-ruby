# Rails Autoscale Agent

[![Build Status](https://travis-ci.org/adamlogic/rails_autoscale_agent.svg?branch=master)](https://travis-ci.org/adamlogic/rails_autoscale_agent)

This gem works together with the [Rails Autoscale](https://railsautoscale.com) Heroku add-on to automatically scale your web and worker dynos as needed. It gathers a minimal set of metrics for each request (and job queue), and periodically posts this data asynchronously to the Rails Autoscale service.

## Requirements

- Rack-based app
- Ruby 2.5 or newer

## Getting Started

Add this line to your application's Gemfile and run `bundle`:

```ruby
gem 'rails_autoscale_agent'
```

This inserts the agent into your Rack middleware stack.

The agent will only communicate with Rails Autoscale if a `RAILS_AUTOSCALE_URL` ENV variable is present, which happens automatically when you install the Heroku add-on. The middleware does nothing if `RAILS_AUTOSCALE_URL` is not present, such as in development or a staging app.

## Non-Rails Rack apps

You'll need to `require 'rails_autoscale_agent/middleware'` and insert the `RailsAutoscaleAgent::Middleware` manually. Insert it before `Rack::Runtime` to ensure accuracy of request queue timings.

## What data is collected?

The middleware agent runs in its own thread so your web requests are not impacted. The following data is submitted periodically to the Rails Autoscale API:

- Ruby version
- Rails version
- Gem version
- Dyno name (example: web.1)
- PID
- Collection of queue time measurements (time and milliseconds)

Rails Autoscale aggregates and stores this information to power the autoscaling algorithm and dashboard visualizations.

## Configuration

Most Rails Autoscale configurations are handled via the settings page on your Rails Autoscale dashboard, but there a few ways you can directly change the behavior of the agent via environment variables:

- `RAILS_AUTOSCALE_DEBUG` - Enables debug logging. See more in the [logging](#logging) section below.
- `RAILS_AUTOSCALE_WORKER_ADAPTER` - Overrides the available worker adapters. See more in the [worker adapters](#worker-adapters) section below.
- `RAILS_AUTOSCALE_LONG_JOBS` - Enables reporting for active workers. See [Handling Long-Running Background Jobs](https://railsautoscale.com/docs/long-running-jobs/) in the Rails Autoscale docs for more.
- `RAILS_AUTOSCALE_MAX_QUEUES` - Worker metrics will only report up to 50 queues by default. If you have more than 50 queues, you'll need to configure this settings or reduce your number of queues.

## Worker adapters

Rails Autoscale supports autoscaling worker dynos. Out of the box, four job backends are supported: Sidekiq, Resque, Delayed Job, and Que. The agent will automatically enable the appropriate worker adapter based on what you have installed in your app.

In some scenarios you might want to override this behavior. Let's say you have both Sidekiq and Resque installed 🤷‍♂️, but you only want Rails Autoscale to collect metrics for Sidekiq. Here's how you'd override that:

```
heroku config:add RAILS_AUTOSCALE_WORKER_ADAPTER=sidekiq
```

You can also disable collection of worker metrics altogether:

```
heroku config:add RAILS_AUTOSCALE_WORKER_ADAPTER=""
```

It's also possible to write a custom worker adapter. See [these docs](https://railsautoscale.com/docs/custom-worker-adapter/) for details.

## Troubleshooting

Once installed, you should see something like this in your development log:

> [RailsAutoscale] Reporter not started: RAILS_AUTOSCALE_URL is not set

In production, run `heroku logs -t | grep RailsAutoscale`, and you should see something like this:

> [RailsAutoscale] Reporter starting, will report every 15 seconds

If you don't see either of these, try running `bundle` again and restarting your Rails application.

You can see more detailed (debug) logging by setting `RAILS_AUTOSCALE_DEBUG` on your Heroku app:

```
heroku config:add RAILS_AUTOSCALE_DEBUG=true
```

See more in the [logging](#logging) section below.

Reach out to help@railsautoscale.com if you run into any other problems.

## Logging

The Rails logger is used by default.
If you wish to use a different logger you can set it on the configuration object:

```ruby
# config/initializers/rails_autoscale_agent.rb
RailsAutoscaleAgent::Config.instance.logger = MyLogger.new
```

Debug logs are silenced by default because Rails apps default to a DEBUG log level in production, and this gem has _very_ chatty debug logs. If you want to see the debug logs, set `RAILS_AUTOSCALE_DEBUG` on your Heroku app:

```
heroku config:add RAILS_AUTOSCALE_DEBUG=true
```

If you find the gem too chatty even without this, you can quiet it down further:

```ruby
# config/initializers/rails_autoscale_agent.rb
RailsAutoscaleAgent::Config.instance.quiet = true
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, commit it, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adamlogic/rails_autoscale_agent.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
