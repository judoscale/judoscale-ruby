# frozen_string_literal: true

require "test_helper"
require "rails_autoscale/report"

module RailsAutoscale
  describe Rack do
    it "adds itself as an adapter with information to be reported to the Rails Autoscale API" do
      adapter = RailsAutoscale.adapters.detect { |adapter| adapter.identifier == :"rails-autoscale-rack" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal RailsAutoscale::WebMetricsCollector

      report = ::RailsAutoscale::Report.new(RailsAutoscale.adapters, RailsAutoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"rails-autoscale-rack")
    end
  end
end
