require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/store'
require 'rails_autoscale_agent/collector'
require 'rails_autoscale_agent/reporter'
require 'rails_autoscale_agent/config'
require 'rails_autoscale_agent/request'

module RailsAutoscaleAgent
  class Middleware
    include Logger

    def initialize(app)
      @app = app
    end

    def call(env)
      config = Config.new(ENV)

      logger.tagged 'RailsAutoscaleAgent', config.to_s do
        if config.api_base_url
          request = Request.new(env, config)

          logger.debug "[Middleware] enter middleware for #{request.fullpath}"

          store = Store.instance
          Reporter.start(config, store)
          Collector.collect(request, store)
        else
          logger.info "[Middleware] RAILS_AUTOSCALE_URL is not set"
        end
      end

      @app.call(env)
    end

  end
end
