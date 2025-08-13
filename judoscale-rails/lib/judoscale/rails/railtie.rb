# frozen_string_literal: true

require "rails"
require "rails/engine"
require "judoscale/request_middleware"
require "judoscale/rails/config"
require "judoscale/utilization_middleware"
require "judoscale/logger"
require "judoscale/reporter"

module Judoscale
  module Rails
    # Inherit from `Engine`, even though we use none its specific features (yet), so we can safely rely
    # on `load_config_initializers` to setup our initializers and avoid loading `config/initializers/*`
    # too early, otherwise we can run into initialization order conflicts with other libraries like
    # `Sentry` and `Scout`, which patch Ruby classes in different ways (`prepend` vs `alias_method`),
    # and may cause `stack level too deep` errors if they are loaded too early in the init process.
    class Railtie < ::Rails::Engine
      include Judoscale::Logger

      def in_rails_console_or_runner?
        # This is gross, but we can't find a more reliable way to detect if we're in a Rails console/runner.
        caller.any? { |call| call.include?("console_command.rb") || call.include?("runner_command.rb") }
      end

      def in_rake_task?(task_regex)
        top_level_tasks = defined?(::Rake) && Rake.respond_to?(:application) && Rake.application.top_level_tasks || []
        top_level_tasks.any? { |task| task_regex.match?(task) }
      end

      def judoscale_config
        # Disambiguate from Judoscale::Rails::Config
        ::Judoscale::Config.instance
      end

      initializer "judoscale.logger" do |app|
        judoscale_config.logger = ::Rails.logger
      end

      initializer "judoscale.request_middleware" do |app|
        app.middleware.insert_before Rack::Runtime, RequestMiddleware
      end

      initializer "judoscale.utilization_middleware", after: :load_config_initializers do |app|
        if judoscale_config.utilization_enabled
          app.middleware.insert_before RequestMiddleware, UtilizationMiddleware
        end
      end

      config.after_initialize do
        if in_rails_console_or_runner?
          logger.debug "No reporting since we're in a Rails console or runner process"
        elsif in_rake_task?(judoscale_config.rake_task_ignore_regex)
          logger.debug "No reporting since we're in a build process"
        elsif judoscale_config.start_reporter_after_initialize
          Reporter.start
        end
      end
    end
  end
end
