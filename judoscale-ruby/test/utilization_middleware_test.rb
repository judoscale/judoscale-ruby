# frozen_string_literal: true

require "test_helper"
require "judoscale/utilization_middleware"

module Judoscale
  class MockApp
    attr_reader :env

    def call(env)
      @env = env
      self
    end
  end

  describe Judoscale::UtilizationMiddleware do
    after { reset_tracker_state }

    let(:app) { MockApp.new }
    let(:env) { {} }
    let(:middleware) { UtilizationMiddleware.new(app) }

    it "passes the request env up the middleware stack, returning the app's response" do
      response = middleware.call(env)

      _(response).must_equal app
      _(app.env).must_equal env
      _(UtilizationTracker.instance.started?).must_equal true
    end
  end
end
