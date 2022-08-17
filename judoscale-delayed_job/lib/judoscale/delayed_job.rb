# frozen_string_literal: true

require "rails-autoscale-core"
require "rails_autoscale/config"
require "rails_autoscale/delayed_job/version"
require "rails_autoscale/delayed_job/metrics_collector"
require "delayed_job_active_record"

RailsAutoscale.add_adapter :"rails-autoscale-delayed_job",
  {
    adapter_version: RailsAutoscale::DelayedJob::VERSION,
    framework_version: Gem.loaded_specs["delayed_job_active_record"].version.to_s # DJ doesn't have a `VERSION` constant
  },
  metrics_collector: RailsAutoscale::DelayedJob::MetricsCollector,
  expose_config: RailsAutoscale::Config::JobAdapterConfig.new(:delayed_job)
