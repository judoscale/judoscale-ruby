module RailsAutoscaleAgent
  MEASUREMENT_TYPES = [
    WAIT_TIME_TYPE = 'wait_time',
  ]
end

require 'rails_autoscale_agent/version'
require 'rails_autoscale_agent/railtie' if defined?(Rails::Railtie) && Rails::Railtie.respond_to?(:initializer)
