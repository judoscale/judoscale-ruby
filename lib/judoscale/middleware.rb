# frozen_string_literal: true

require "judoscale/store"
require "judoscale/reporter"
require "judoscale/config"
require "judoscale/logger"
require "judoscale/request"

module Judoscale
  class Middleware
    include Logger

    def initialize(app)
      @app = app
    end

    def call(env)
      config = Config.instance
      request = Request.new(env, config)

      unless request.ignore?
        queue_time = request.queue_time
        network_time = request.network_time
      end

      store = Store.instance
      Reporter.start(config, store)

      if queue_time
        # NOTE: Expose queue time to the app
        env["judoscale.queue_time"] = queue_time
        store.push :qt, queue_time

        unless network_time.zero?
          env["judoscale.network_time"] = network_time
          store.push :nt, network_time
        end

        logger.debug "Request queue_time=#{queue_time}ms network_time=#{network_time}ms request_id=#{request.id} size=#{request.size}"
      end

      @app.call(env)
    end
  end
end
