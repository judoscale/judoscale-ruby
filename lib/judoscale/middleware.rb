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

      queue_time = request.queue_time unless request.ignore?

      store = Store.instance
      Reporter.start(config, store)

      if queue_time
        # NOTE: Expose queue time to the app
        env["judoscale.queue_time"] = queue_time
        store.push queue_time
      end

      @app.call(env)
    end
  end
end
