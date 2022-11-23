# frozen_string_literal: true

require "rails-autoscale-core"
require "judoscale/web/version"
require "judoscale/web/railtie"
require "judoscale/web_metrics_collector"
require "rails/version"

Judoscale.add_adapter :"rails-autoscale-web", {
  adapter_version: Judoscale::Web::VERSION,
  framework_version: ::Rails.version
}, metrics_collector: Judoscale::WebMetricsCollector
