# frozen_string_literal: true

require "rails"
require "rails/railtie"
require "rails_autoscale/request_middleware"
require "rails_autoscale/config"
require "rails_autoscale/logger"
require "rails_autoscale/reporter"

module RailsAutoscale
  module Web
    class Railtie < ::Rails::Railtie
      include RailsAutoscale::Logger

      initializer "RailsAutoscale.logger" do |app|
        Config.instance.logger = ::Rails.logger
      end

      initializer "RailsAutoscale.request_middleware" do |app|
        logger.info "Preparing request middleware"
        app.middleware.insert_before Rack::Runtime, RequestMiddleware
      end

      config.after_initialize do
        Reporter.start
      end
    end
  end
end
