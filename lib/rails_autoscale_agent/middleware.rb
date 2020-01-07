# frozen_string_literal: true

require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/store'
require 'rails_autoscale_agent/reporter'
require 'rails_autoscale_agent/config'
require 'rails_autoscale_agent/request'
require 'rails_autoscale_agent/puma_utilization'

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

        store = Store.instance
        Reporter.start(config, store)

        if !request.ignore? && queue_time = request.queue_time
          # NOTE: Expose queue time to the app
          env['queue_time'] = queue_time
          store.push queue_time

          if puma_util = PumaUtilization.instance.utilization
            store.push puma_util, Time.now, PumaUtilization::QUEUE
          end

          logger.debug "Collected queue_time=#{queue_time}ms request_id=#{request.id} request_size=#{request.size} puma_util=#{puma_util}"
        end
      end

      @app.call(env)
    end

  end
end
