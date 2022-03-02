# frozen_string_literal: true

require "test_helper"
require "judoscale/job_metrics_collector"

module Judoscale
  describe JobMetricsCollector do
    describe ".collect?" do
      it "collects only from the first dynos in the formation, to avoid redundant collection from multiple dynos" do
        %w[web.1 worker.1 custom_type.1].each do |dyno|
          Judoscale.configure { |config| config.dyno = dyno }

          _(JobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true
        end

        %w[web.2 worker.15 custom_type.101].each do |dyno|
          Judoscale.configure { |config| config.dyno = dyno }

          _(JobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
        end
      end
    end
  end
end
