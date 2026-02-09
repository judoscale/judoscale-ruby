# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/config"
require "judoscale/version"
require "judoscale/resque/metrics_collector"
require "resque"
require "judoscale/resque/latency_extension"

Judoscale.add_adapter :"judoscale-resque",
  {
    adapter_version: Judoscale::VERSION,
    runtime_version: ::Resque::VERSION
  },
  metrics_collector: Judoscale::Resque::MetricsCollector,
  expose_config: Judoscale::Config::JobAdapterConfig.new(:resque)
