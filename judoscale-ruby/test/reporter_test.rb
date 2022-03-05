# frozen_string_literal: true

require "test_helper"
require "judoscale/reporter"
require "judoscale/config"

module Judoscale
  class TestJobMetricsCollector < JobMetricsCollector
    def self.adapter_name
      "Sidekiq" # TODO: Remove once we make this dynamic and/or shared somehow.
    end
  end

  class TestWebMetricsCollector < WebMetricsCollector
    def collect
      [Metric.new(:qt, 1, Time.now)]
    end
  end

  describe Reporter do
    before {
      Judoscale.configure do |config|
        config.dyno = "web.1"
        config.api_base_url = "http://example.com/api/test-token"
      end
    }

    describe ".start" do
      before {
        Judoscale.add_adapter :test_web, {}, metrics_collector: TestWebMetricsCollector
        Judoscale.add_adapter :test_job, {}, metrics_collector: TestJobMetricsCollector
      }

      after {
        Judoscale.remove_adapter :test_web
        Judoscale.remove_adapter :test_job
      }

      it "initializes the reporter with all registered web and job metrics collectors when on the first dyno" do
        reporter_mock = Minitest::Mock.new
        reporter_mock.expect :started?, false
        reporter_mock.expect :start!, true do |config, metrics_collectors|
          _(metrics_collectors.size).must_equal 2
          _(metrics_collectors[0]).must_be_instance_of TestWebMetricsCollector
          _(metrics_collectors[1]).must_be_instance_of TestJobMetricsCollector
        end

        Reporter.stub(:instance, reporter_mock) {
          Reporter.start(Config.instance)
        }

        assert_mock reporter_mock
      end

      it "initializes the reporter only with registered web metrics collectors on other dynos to avoid redundant worker metrics" do
        Judoscale.configure { |config| config.dyno = "web.2" }

        reporter_mock = Minitest::Mock.new
        reporter_mock.expect :started?, false
        reporter_mock.expect :start!, true do |config, metrics_collectors|
          _(metrics_collectors.size).must_equal 1
          _(metrics_collectors[0]).must_be_instance_of TestWebMetricsCollector
        end

        Reporter.stub(:instance, reporter_mock) {
          Reporter.start(Config.instance)
        }

        assert_mock reporter_mock
      end

      it "does not initialize the reporter more than once" do
        reporter_mock = Minitest::Mock.new
        reporter_mock.expect :started?, true

        Reporter.stub(:instance, reporter_mock) {
          Reporter.start(Config.instance)
        }

        assert_mock reporter_mock
      end
    end

    describe "#start!" do
      after {
        Reporter.instance.stop!
      }

      def run_reporter_start_thread(collectors: [])
        stub_reporter_loop {
          reporter_thread = Reporter.instance.start!(Config.instance, collectors)
          reporter_thread.join
        }
      end

      def stub_reporter_loop
        Reporter.instance.stub(:loop, ->(&blk) { blk.call }) {
          Reporter.instance.stub(:sleep, true) {
            yield
          }
        }
      end

      it "sends a report with collected metrics" do
        metrics_collector = TestWebMetricsCollector.new
        metrics = metrics_collector.collect

        expected_body = Report.new(Judoscale.adapters, Config.instance, metrics).as_json
        stub = stub_request(:post, "http://example.com/api/test-token/adapter/v1/metrics")
          .with(body: JSON.generate(expected_body))

        run_reporter_start_thread(collectors: [metrics_collector])

        assert_requested stub
      end

      it "logs exceptions when reporting collected information" do
        Reporter.instance.stub(:report!, ->(*) { raise "REPORT BOOM!" }) {
          run_reporter_start_thread
        }

        _(log_string).must_include "Reporter error: #<RuntimeError: REPORT BOOM!>"
        _(log_string).must_include "lib/judoscale/reporter.rb"
      end

      it "logs exceptions when collecting information" do
        metrics_collector = TestWebMetricsCollector.new

        metrics_collector.stub(:collect, ->(*) { raise "ADAPTER BOOM!" }) {
          run_reporter_start_thread(collectors: [metrics_collector])
        }

        _(log_string).must_include "Reporter error: #<RuntimeError: ADAPTER BOOM!>"
        _(log_string).must_include "lib/judoscale/reporter.rb"
      end
    end

    describe "#report!" do
      it "reports collected metrics to the API" do
        metrics = [
          Metric.new(:qt, 11, Time.at(1_000_000_001)), # web metric
          Metric.new(:qt, 22, Time.at(1_000_000_002), "high") # worker metric
        ]

        expected_body = Report.new(Judoscale.adapters, Config.instance, metrics).as_json
        stub = stub_request(:post, "http://example.com/api/test-token/adapter/v1/metrics")
          .with(body: JSON.generate(expected_body))

        Reporter.instance.send :report!, Config.instance, metrics

        assert_requested stub
      end

      it "logs reporter failures" do
        stub_request(:post, %r{http://example.com/api/test-token/adapter/v1/metrics})
          .to_return(body: "oops", status: 503)

        metrics = [Metric.new(:qt, 1, Time.at(1_000_000_001))] # need some metric to trigger reporting

        log_io = StringIO.new
        stub_logger = ::Logger.new(log_io)

        Reporter.instance.stub(:logger, stub_logger) {
          Reporter.instance.send :report!, Config.instance, metrics
        }

        _(log_io.string).must_include "ERROR -- : Reporter failed: 503 - "
      end
    end
  end
end
