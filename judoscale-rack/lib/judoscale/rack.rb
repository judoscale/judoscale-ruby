# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/version"
require "judoscale/web_metrics_collector"
require "judoscale/request_middleware"
require "rack"

# For Rack apps, Judoscale::RequestMiddleware must be manually inserted into
# the app's middleware chain.

Judoscale.add_adapter :"judoscale-rack", {
  adapter_version: Judoscale::VERSION,
  # Rack deprecated `version` in v3, removed in v3.1.
  framework_version: ::Rack.respond_to?(:release) ? ::Rack.release : ::Rack.version
}, metrics_collector: Judoscale::WebMetricsCollector
