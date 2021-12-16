# frozen_string_literal: true

require 'judoscale/middleware'
require 'judoscale/logger'

module Judoscale
  class Railtie < Rails::Railtie
    include Logger

    initializer "judoscale.middleware" do |app|
      logger.info "Preparing middleware"
      app.middleware.insert_before Rack::Runtime, Middleware
    end
  end
end
