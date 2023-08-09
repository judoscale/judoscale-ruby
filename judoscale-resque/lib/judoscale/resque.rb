# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/config"
require "judoscale/resque/version"
require "judoscale/resque/metrics_collector"
require "resque"
require "judoscale/resque/latency_extension"

Judoscale::Config.instance.allow_rake_tasks << /resque:work/

Judoscale.add_adapter :"judoscale-resque",
  {
    adapter_version: Judoscale::Resque::VERSION,
    framework_version: ::Resque::VERSION
  },
  metrics_collector: Judoscale::Resque::MetricsCollector,
  expose_config: Judoscale::Config::JobAdapterConfig.new(:resque)
