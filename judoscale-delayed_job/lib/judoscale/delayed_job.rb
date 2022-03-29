# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/config"
require "judoscale/delayed_job/version"
require "judoscale/delayed_job/metrics_collector"
require "delayed_job_active_record"

Judoscale.add_adapter :"judoscale-delayed_job", {
  adapter_version: Judoscale::DelayedJob::VERSION,
  framework_version: "TODO" # ::DelayedJob::VERSION
}, metrics_collector: Judoscale::DelayedJob::MetricsCollector

Judoscale::Config.add_adapter_config :delayed_job, Judoscale::Config::JobAdapterConfig
