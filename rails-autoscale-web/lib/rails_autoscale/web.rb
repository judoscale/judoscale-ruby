# frozen_string_literal: true

require "rails-autoscale-core"
require "rails_autoscale/web/version"
require "rails_autoscale/web/railtie"
require "rails_autoscale/web_metrics_collector"
require "rails/version"

RailsAutoscale.add_adapter :"rails-autoscale-web", {
  adapter_version: RailsAutoscale::Web::VERSION,
  framework_version: ::Rails.version
}, metrics_collector: RailsAutoscale::WebMetricsCollector
