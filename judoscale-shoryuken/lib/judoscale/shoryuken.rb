# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/config"
require "judoscale/version"
require "judoscale/shoryuken/metrics_collector"
require "shoryuken"

Judoscale.add_adapter :"judoscale-shoryuken",
  {
    adapter_version: Judoscale::VERSION,
    framework_version: ::Shoryuken::VERSION
  },
  metrics_collector: Judoscale::Shoryuken::MetricsCollector,
  expose_config: Judoscale::Config::JobAdapterConfig.new(:shoryuken, support_busy_jobs: false)
