# frozen_string_literal: true

require "rails-autoscale-core"
require "judoscale/config"
require "judoscale/sidekiq/version"
require "judoscale/sidekiq/metrics_collector"
require "sidekiq/api"

Judoscale.add_adapter :"rails-autoscale-sidekiq",
  {
    adapter_version: Judoscale::Sidekiq::VERSION,
    framework_version: ::Sidekiq::VERSION
  },
  metrics_collector: Judoscale::Sidekiq::MetricsCollector,
  expose_config: Judoscale::Config::JobAdapterConfig.new(:sidekiq)
