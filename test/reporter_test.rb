# frozen_string_literal: true

require "test_helper"
require "judoscale/reporter"
require "judoscale/config"

module Judoscale
  class TestMetricsCollector < MetricsCollector
    def collect
    end
  end

  describe Reporter do
    before {
      Judoscale.configure do |config|
        config.dyno = "web.1"
        config.api_base_url = "http://example.com/api/test-token"
      end
    }

    describe "#start!" do
      before {
        stub_request(:post, %r{registrations}).to_return(body: "{}")
      }
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

      it "logs exceptions when reporting collected information" do
        Reporter.instance.stub(:report!, ->(*) { raise "REPORT BOOM!" }) {
          run_reporter_start_thread
        }

        _(log_string).must_include "Reporter error: #<RuntimeError: REPORT BOOM!>"
        _(log_string).must_include "lib/judoscale/reporter.rb"
      end

      it "logs exceptions when collecting information" do
        metrics_collector = TestMetricsCollector.new

        metrics_collector.stub(:collect, ->(*) { raise "ADAPTER BOOM!" }) {
          run_reporter_start_thread(collectors: [metrics_collector])
        }

        _(log_string).must_include "Reporter error: #<RuntimeError: ADAPTER BOOM!>"
        _(log_string).must_include "lib/judoscale/reporter.rb"
      end
    end

    describe "#report!" do
      it "reports stored metrics to the API" do
        expected_body = {dyno: "web.1", metrics: [[1000000001, 11, "qt", nil], [1000000002, 22, "qt", "high"]]}
        stub = stub_request(:post, "http://example.com/api/test-token/adapter/v1/metrics").with(body: expected_body)

        metrics = [
          Metric.new(:qt, Time.at(1_000_000_001), 11), # web metric
          Metric.new(:qt, Time.at(1_000_000_002), 22, "high") # worker metric
        ]

        Reporter.instance.send :report!, Config.instance, metrics

        assert_requested stub
      end

      it "logs reporter failures" do
        stub_request(:post, %r{http://example.com/api/test-token/adapter/v1/metrics})
          .to_return(body: "oops", status: 503)

        metrics = [Metric.new(:qt, Time.at(1_000_000_001), 1)] # need some metric to trigger reporting

        log_io = StringIO.new
        stub_logger = ::Logger.new(log_io)

        Reporter.instance.stub(:logger, stub_logger) {
          Reporter.instance.send :report!, Config.instance, metrics
        }

        _(log_io.string).must_include "ERROR -- : Reporter failed: 503 - "
      end
    end

    describe "#register!" do
      it "registers the reporter with contextual info" do
        expected_body = {
          registration: {
            pid: Process.pid,
            ruby_version: RUBY_VERSION,
            rails_version: "5.0.fake",
            gem_version: Judoscale::VERSION,
            collectors: ""
          }
        }
        response = {}.to_json
        stub = stub_request(:post, "http://example.com/api/test-token/adapter/v1/registrations")
          .with(body: expected_body)
          .to_return(body: response)

        Reporter.instance.send :register!, Config.instance, []

        assert_requested stub
      end
    end
  end
end
