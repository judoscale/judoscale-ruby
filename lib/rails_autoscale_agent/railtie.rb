require 'rails_autoscale_agent/middleware'

module RailsAutoscaleAgent
  class Railtie < Rails::Railtie
    initializer "rails_autoscale_agent.middleware" do |app|
      app.middleware.insert_before Rack::Runtime, Middleware
    end
  end
end
