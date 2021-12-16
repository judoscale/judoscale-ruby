# frozen_string_literal: true

require "judoscale/store"
require "judoscale/reporter"
require "judoscale/config"
require "judoscale/request"

module Judoscale
  class Middleware
    def initialize(app)
      @app = app
    end

    def call(env)
      config = Config.instance
      request = Request.new(env, config)

      store = Store.instance
      Reporter.start(config, store)

      if !request.ignore? && queue_time = request.queue_time
        # NOTE: Expose queue time to the app
        env["queue_time"] = queue_time
        store.push queue_time
      end

      @app.call(env)
    end
  end
end
