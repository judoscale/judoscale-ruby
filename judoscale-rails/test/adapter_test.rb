# frozen_string_literal: true

require "test_helper"

module Judoscale
  describe Rails do
    it "adds itself as an adapter with information to be reported to the Judoscale API" do
      adapter = Judoscale.adapters.detect { |adapter| adapter.identifier == :"judoscale-rails" }
      _(adapter).wont_be_nil
      _(adapter.metrics_collector).must_equal Judoscale::WebMetricsCollector

      report = ::Judoscale::Report.new(Judoscale.adapters, Judoscale::Config.instance, [])
      _(report.as_json[:adapters]).must_include(:"judoscale-rails")
    end
  end
end
