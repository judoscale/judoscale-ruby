# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/config"
require "judoscale/resque/version"
require "judoscale/resque/metrics_collector"
require "resque"

Judoscale.add_adapter :"judoscale-resque", {
  adapter_version: Judoscale::Resque::VERSION,
  framework_version: ::Resque::VERSION
}, metrics_collector: Judoscale::Resque::MetricsCollector

Judoscale::Config.add_adapter_config Judoscale::Config::JobAdapterConfig.new(:resque)
