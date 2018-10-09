# frozen_string_literal: true

module RailsAutoscaleAgent
end

require 'rails_autoscale_agent/version'
require 'rails_autoscale_agent/railtie' if defined?(Rails::Railtie) && Rails::Railtie.respond_to?(:initializer)
