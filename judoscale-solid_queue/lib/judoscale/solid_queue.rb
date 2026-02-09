# frozen_string_literal: true

require "solid_queue"
require "judoscale-ruby"
require "judoscale/config"
require "judoscale/version"
require "judoscale/solid_queue/metrics_collector"

Judoscale.add_adapter :"judoscale-solid_queue",
  {
    adapter_version: Judoscale::VERSION,
    framework_version: ::SolidQueue::VERSION
  },
  metrics_collector: Judoscale::SolidQueue::MetricsCollector,
  expose_config: Judoscale::Config::JobAdapterConfig.new(:solid_queue)
