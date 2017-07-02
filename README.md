# Rails Autoscale Agent

This gem works together with the Rails Autoscale Heroku add-on
to automatically scale your web dynos as needed.
It gathers a minimal set of metrics for each request,
and periodically posts this data asynchronously to the Rails Autoscale service.

## Requirements

We've tested this with Rails versions 3.2 and higher and Ruby versions 1.9.3 and higher.

## Getting Started

Add this line to your application's Gemfile and run `bundle`:

```ruby
gem 'rails_autoscale_agent'
```

This will automatically insert the agent into your Rack middleware stack.

The agent will only communicate with Rails Autoscale if a `RAILS_AUTOSCALE_URL` ENV variable is present,
which happens automatically when you install the Heroku add-on.
In development (or anytime the ENV var is missing), the middleware will still produce
`INFO`-level log output to your Rails log.

## Development

After checking out the repo, run `bin/setup` to install dependencies.
Then, run `rake spec` to run the tests.
You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.
To release a new version, update the version number in `version.rb`,
and then run `bundle exec rake release`, which will create a git tag for the version,
push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adamlogic/rails_autoscale_agent.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

