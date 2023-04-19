# frozen_string_literal: true

require "test_helper"
require "judoscale/web_metrics_collector"

module Judoscale
  describe WebMetricsCollector do
    let(:store) { MetricsStore.instance }

    describe ".collect?" do
      it "collects only from web containers in the formation, to avoid unnecessary collection on workers" do
        [
          ["web", "1"],
          ["web", "15"],
          ["web", "101"],
          ["srv-cfa1es5a49987h4vcvfg", "5497f74465-m5wwr", "web"],
          ["srv-cfa1es5a49987h4vcvfg", "aaacff2165-m5wwr", "web"]
        ].each do |args|
          Judoscale.configure do |config|
            config.current_runtime_container = Config::RuntimeContainer.new(*args)
          end

          _(WebMetricsCollector.collect?(Judoscale::Config.instance)).must_equal true
        end

        [
          ["worker", "1"],
          ["secondary", "15"],
          ["periodic", "101"],
          ["srv-baa1e15a49a87h4vcv22", "5497f74465-m5wwr", "worker"],
          ["srv-aff1e14249124abch4vc", "abc18ce8fa-abb1w", "worker"]
        ].each do |args|
          Judoscale.configure do |config|
            config.current_runtime_container = Config::RuntimeContainer.new(*args)
          end

          _(WebMetricsCollector.collect?(Judoscale::Config.instance)).must_equal false
        end
      end
    end

    describe "#collect" do
      it "flushes the metrics previously collected from the store" do
        collector = WebMetricsCollector.new
        _(collector.collect).must_be :empty?

        1.upto(3) { |i| store.push :qt, i, Time.now }
        _(store.metrics.size).must_equal 3

        collected_metrics = collector.collect

        _(collected_metrics.size).must_equal 3
        _(collected_metrics.map(&:value)).must_equal [1, 2, 3]
        _(collected_metrics[0].identifier).must_equal :qt
        _(store.metrics).must_be :empty?
      end
    end
  end
end
