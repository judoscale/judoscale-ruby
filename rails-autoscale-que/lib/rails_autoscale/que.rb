# frozen_string_literal: true

require "rails-autoscale-core"
require "rails_autoscale/config"
require "rails_autoscale/que/version"
require "rails_autoscale/que/metrics_collector"
require "que"

RailsAutoscale.add_adapter :"rails-autoscale-que",
  {
    adapter_version: RailsAutoscale::Que::VERSION,
    framework_version: ::Que::VERSION
  },
  metrics_collector: RailsAutoscale::Que::MetricsCollector,
  expose_config: RailsAutoscale::Config::JobAdapterConfig.new(:que)
