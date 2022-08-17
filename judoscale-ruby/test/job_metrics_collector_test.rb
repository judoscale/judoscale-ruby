# frozen_string_literal: true

require "test_helper"
require "judoscale/job_metrics_collector"

module Judoscale
  describe JobMetricsCollector do
    describe ".collect?" do
      it "collects only from the first dynos in the formation, to avoid redundant collection from multiple dynos" do
        %w[web.1 worker.1 custom_type.1].each do |dyno|
          Judoscale.configure { |config| config.dyno = dyno }

          _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true
        end

        %w[web.2 worker.15 custom_type.101].each do |dyno|
          Judoscale.configure { |config| config.dyno = dyno }

          _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
        end
      end

      it "skips collecting if the adapter has been explicitly disabled" do
        Judoscale.configure { |config|
          config.dyno = "web.1"
          config.test_job_config.enabled = true
        }

        _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true

        Judoscale.configure { |config| config.test_job_config.enabled = false }

        _(Test::TestJobMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
      end
    end
  end
end
