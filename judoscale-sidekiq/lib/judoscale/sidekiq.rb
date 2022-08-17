# frozen_string_literal: true

require "rails-autoscale-core"
require "rails_autoscale/config"
require "rails_autoscale/sidekiq/version"
require "rails_autoscale/sidekiq/metrics_collector"
require "sidekiq/api"

RailsAutoscale.add_adapter :"rails-autoscale-sidekiq",
  {
    adapter_version: RailsAutoscale::Sidekiq::VERSION,
    framework_version: ::Sidekiq::VERSION
  },
  metrics_collector: RailsAutoscale::Sidekiq::MetricsCollector,
  expose_config: RailsAutoscale::Config::JobAdapterConfig.new(:sidekiq)
