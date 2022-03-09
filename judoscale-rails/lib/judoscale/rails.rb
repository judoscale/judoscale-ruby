# frozen_string_literal: true

require "judoscale-ruby"
require "judoscale/rails/version"
require "judoscale/rails/railtie"
require "judoscale/web_metrics_collector"
require "rails/version"

Judoscale.add_adapter :"judoscale-rails", {
  adapter_version: Judoscale::Rails::VERSION,
  framework_version: ::Rails.version
}, metrics_collector: Judoscale::WebMetricsCollector
