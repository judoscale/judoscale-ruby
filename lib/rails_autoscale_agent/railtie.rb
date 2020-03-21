# frozen_string_literal: true

require 'rails_autoscale_agent/middleware'
require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  class Railtie < Rails::Railtie
    include Logger

    initializer "rails_autoscale_agent.middleware" do |app|
      logger.info "Preparing middleware"
      app.middleware.insert_before Rack::Runtime, Middleware
    end
  end
end
