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
      logger.tagged 'RailsAutoscale' do
        config = Config.instance
        request = Request.new(env, config)

        logger.debug "Middleware entered - request_id=#{request.id} path=#{request.path} method=#{request.method} request_size=#{request.size}"

        store = Store.instance
        Reporter.start(config, store)
        Collector.collect(request, store) unless request.ignore?
      end

      @app.call(env)
    end

  end
end
