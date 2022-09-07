# frozen_string_literal: true

require "rails-autoscale-core"
require "rails_autoscale/config"
require "rails_autoscale/resque/version"
require "rails_autoscale/resque/metrics_collector"
require "resque"
require "rails_autoscale/resque/latency_extension"

RailsAutoscale.add_adapter :"rails-autoscale-resque",
  {
    adapter_version: RailsAutoscale::Resque::VERSION,
    framework_version: ::Resque::VERSION
  },
  metrics_collector: RailsAutoscale::Resque::MetricsCollector,
  expose_config: RailsAutoscale::Config::JobAdapterConfig.new(:resque)
