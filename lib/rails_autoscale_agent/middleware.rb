require 'rails_autoscale_agent/metrics_collector'
require 'rails_autoscale_agent/metrics_reporter'

module RailsAutoscaleAgent
  class Middleware

    def initialize(app)
      @app = app
    end

    def call(env)
      if autoscale_url = ENV['RAILS_AUTOSCALE_URL']
        puts "[rails-autoscale] [Middleware] enter middleware for #{env['HTTP_HOST']}#{env['PATH_INFO']}"
        MetricsReporter.start(autoscale_url)
        MetricsCollector.collect(env)
      else
        puts "[rails-autoscale] [Middleware] RAILS_AUTOSCALE_URL is not set"
      end

      @app.call(env)
    end

  end
end
