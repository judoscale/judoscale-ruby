# Rails Autoscale Agent

[![Build Status](https://travis-ci.org/adamlogic/rails_autoscale_agent.svg?branch=master)](https://travis-ci.org/adamlogic/rails_autoscale_agent)

This gem works together with the [Rails Autoscale](https://railsautoscale.com) Heroku add-on to automatically scale your web and worker dynos as needed. It gathers a minimal set of metrics for each request (and job queue), and periodically posts this data asynchronously to the Rails Autoscale service.

## Requirements

Tested with Rails versions 3.2 and higher and Ruby versions 1.9.3 and higher.

## Getting Started

Add this line to your application's Gemfile and run `bundle`:

```ruby
gem 'rails_autoscale_agent'
```

This inserts the agent into your Rack middleware stack.

The agent will only communicate with Rails Autoscale if a `RAILS_AUTOSCALE_URL` ENV variable is present, which happens automatically when you install the Heroku add-on. The middleware does nothing if `RAILS_AUTOSCALE_URL` is not present, such as in development or a staging app.

## Non-Rails Rack apps

You'll need to insert the `RailsAutoscaleAgent::Middleware` manually. Insert it before `Rack::Runtime` to ensure accuracy of request queue timings.

## Changing the logger

The Rails logger is used by default.
If you wish to use a different logger you can set it on the configuration object:

```ruby
# config/initializers/rails_autoscale_agent.rb
RailsAutoscaleAgent::Config.instance.logger = MyLogger.new
```

## What data is collected?

The middleware agent runs in its own thread so your web requests are not impacted. The following data is submitted periodically to the Rails Autoscale API:

- Ruby version
- Rails version
- Gem version
- Dyno name (example: web.1)
- PID
- Collection of queue time measurements (time and milliseconds)

Rails Autoscale aggregates and stores this information to power the autoscaling algorithm and dashboard visualizations.

## Troubleshooting

Once installed, you should see something like this in your development log:

> [RailsAutoscale] Reporter not started: RAILS_AUTOSCALE_URL is not set

In production, run `heroku logs -t | grep RailsAutoscale`, and you should see something like this:

> [RailsAutoscale] Reporter starting, will report every 15 seconds

If you don't see either of these, try running `bundle` again and restarting your Rails application.

You can see more detailed (debug) logging by setting the `RAILS_AUTOSCALE_DEBUG` env var on your Heroku app:

```
heroku config:add RAILS_AUTOSCALE_DEBUG=true
```

Debug logs are silenced by default because Rails apps default to a DEBUG log level in production,
and these can get very noisy with this gem.

Reach out to help@railsautoscale.com if you run into any other problems.

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, commit it, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adamlogic/rails_autoscale_agent.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
