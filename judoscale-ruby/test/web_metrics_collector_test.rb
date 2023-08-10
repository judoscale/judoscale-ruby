# frozen_string_literal: true

require "test_helper"
require "rake_mock"
require "minitest/stub_const"
require "judoscale/web_metrics_collector"
require "judoscale/config"

module RailsMock
  module Command
    class GenerateCommand; end
  end
end

module Judoscale
  describe WebMetricsCollector do
    describe ".collect?" do
      it "returns true when not running in a rake task" do
        Object.stub_const :Rake, nil do
          _(WebMetricsCollector.collect?(Config.instance)).must_equal true
        end

        Object.stub_const :Rake, RakeMock.new([]) do
          _(WebMetricsCollector.collect?(Config.instance)).must_equal true
        end
      end

      it "returns false when running in a generator" do
        Object.stub_const :Rails, RailsMock do
          _(WebMetricsCollector.collect?(Config.instance)).must_equal false
        end
      end

      it "returns false when running in a rake task" do
        Object.stub_const :Rake, RakeMock.new(["foo"]) do
          _(WebMetricsCollector.collect?(Config.instance)).must_equal false
        end
      end

      it "returns true when running in a whitelisted rake task" do
        config = Config.instance
        config.allow_rake_tasks << /foo/

        Object.stub_const :Rake, RakeMock.new(["bar", "foo"]) do
          _(WebMetricsCollector.collect?(config)).must_equal true
        end
      end
    end

    describe "#collect" do
      let(:store) { MetricsStore.instance }

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
