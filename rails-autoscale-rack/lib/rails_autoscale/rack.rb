# frozen_string_literal: true

require "rails-autoscale-core"
require "rails_autoscale/rack/version"
require "rails_autoscale/web_metrics_collector"
require "rails_autoscale/request_middleware"
require "rack"

# For Rack apps, RailsAutoscale::RequestMiddleware must be manually inserted into
# the app's middleware chain.

RailsAutoscale.add_adapter :"rails-autoscale-rack", {
  adapter_version: RailsAutoscale::Rack::VERSION,
  framework_version: ::Rack.version
}, metrics_collector: RailsAutoscale::WebMetricsCollector
