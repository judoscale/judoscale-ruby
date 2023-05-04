# frozen_string_literal: true

require "rails"
require "rails/railtie"
require "judoscale/request_middleware"
require "judoscale/config"
require "judoscale/logger"
require "judoscale/reporter"

module Judoscale
  module Rails
    class Railtie < ::Rails::Railtie
      include Judoscale::Logger

      initializer "Judoscale.logger" do |app|
        Config.instance.logger = ::Rails.logger
      end

      initializer "Judoscale.request_middleware" do |app|
        logger.info "Preparing request middleware"
        app.middleware.insert_before Rack::Runtime, RequestMiddleware
      end

      config.after_initialize do
        # Don't start the reporter in a Rails console.
        # NOTE: This is untested because we initialize the Rails test app in test_helper.rb,
        # so the reporter has already started before any of the tests run.
        Reporter.start unless defined?(::Rails::Console)
      end
    end
  end
end
