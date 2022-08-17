# frozen_string_literal: true

require "rails-autoscale-core"
require "rails_autoscale/rails/version"
require "rails_autoscale/rails/railtie"
require "rails_autoscale/web_metrics_collector"
require "rails/version"

RailsAutoscale.add_adapter :"rails-autoscale-web", {
  adapter_version: RailsAutoscale::Rails::VERSION,
  framework_version: ::Rails.version
}, metrics_collector: RailsAutoscale::WebMetricsCollector
