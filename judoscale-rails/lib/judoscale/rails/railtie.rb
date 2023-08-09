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

      def in_rails_console?
        defined?(::Rails::Console)
      end

      def in_rake_task?
        defined?(::Rake) && Rake.respond_to?(:application)
      end

      initializer "Judoscale.logger" do |app|
        Config.instance.logger = ::Rails.logger
      end

      initializer "Judoscale.request_middleware" do |app|
        if !in_rails_console? && !in_rake_task?
          logger.debug "Preparing request middleware"
          app.middleware.insert_before Rack::Runtime, RequestMiddleware
        end
      end

      config.after_initialize do
        # Don't suppress this in Rake tasks since some job adapters use Rake tasks to run jobs.
        Reporter.start unless in_rails_console?
      end
    end
  end
end
