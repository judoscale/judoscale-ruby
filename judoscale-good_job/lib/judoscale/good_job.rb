# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/config"
require "judoscale/good_job/version"
require "judoscale/good_job/metrics_collector"
require "good_job_active_record"

Judoscale.add_adapter :"judoscale-good_job",
  {
    adapter_version: Judoscale::GoodJob::VERSION,
    framework_version: Gem.loaded_specs["good_job_active_record"].version.to_s # DJ doesn't have a `VERSION` constant
  },
  metrics_collector: Judoscale::GoodJob::MetricsCollector,
  expose_config: Judoscale::Config::JobAdapterConfig.new(:good_job)
