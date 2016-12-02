require 'rails_autoscale_agent/middleware'

module RailsAutoscaleAgent
  class Railtie < Rails::Railtie
    initializer "rails_autoscale.setup" do |app|
      app.middleware.use Middleware
    end
  end
end
