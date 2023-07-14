# frozen_string_literal: true

require "test_helper"
require "judoscale/reporter"
require "judoscale/config"

module Judoscale
  describe Reporter do
    before {
      Judoscale.configure do |config|
        config.current_runtime_container = Config::RuntimeContainer.new("web.1")
        config.api_base_url = "http://example.com/api/test-token"
      end
    }

    describe ".start" do
      it "initializes the reporter with the current configuration and loaded adapters" do
        reporter_mock = Minitest::Mock.new
        reporter_mock.expect :started?, false
        reporter_mock.expect :start!, true, [Config.instance, Judoscale.adapters]

        Reporter.stub(:instance, reporter_mock) {
          Reporter.start
        }

        assert_mock reporter_mock
      end

      it "does not initialize the reporter more than once" do
        reporter_mock = Minitest::Mock.new
        reporter_mock.expect :started?, true

        Reporter.stub(:instance, reporter_mock) {
          Reporter.start
        }

        assert_mock reporter_mock
      end
    end

    describe "#start!" do
      after {
        Reporter.instance.stop!
      }

      def run_reporter_start_thread
        stub_reporter_loop {
          reporter_thread = Reporter.instance.start!(Config.instance, Judoscale.adapters)
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

      it "sends a report with collected metrics in the reporter thread loop" do
        web_metrics = Test::TestWebMetricsCollector.new.collect
        job_metrics = Test::TestJobMetricsCollector.new.collect
        all_metrics = web_metrics + job_metrics

        expected_body = Report.new(Judoscale.adapters, Config.instance, all_metrics).as_json
        stub = stub_request(:post, "http://example.com/api/test-token/v3/reports")
          .with(body: JSON.generate(expected_body))

        run_reporter_start_thread

        assert_requested stub
      end

      it "initializes the reporter with all registered web and job metrics collectors when on the first runtime container" do
        run_loop_stub = proc do |config, metrics_collectors|
          _(metrics_collectors.size).must_equal 2
          _(metrics_collectors[0]).must_be_instance_of Test::TestWebMetricsCollector
          _(metrics_collectors[1]).must_be_instance_of Test::TestJobMetricsCollector
        end

        Reporter.instance.stub(:run_loop, run_loop_stub) {
          Reporter.instance.start!(Config.instance, Judoscale.adapters)
        }
      end

      it "initializes the reporter only with registered web metrics collectors on subsequent runtime containers to avoid redundant worker metrics" do
        Judoscale.configure do |config|
          config.current_runtime_container = Config::RuntimeContainer.new("web.2")
        end

        run_loop_stub = proc do |config, metrics_collectors|
          _(metrics_collectors.size).must_equal 1
          _(metrics_collectors[0]).must_be_instance_of Test::TestWebMetricsCollector
        end

        Reporter.instance.stub(:run_loop, run_loop_stub) {
          Reporter.instance.start!(Config.instance, Judoscale.adapters)
        }
      end

      it "respects explicitly disabled job adapters / metrics collectors via config when initializing the reporter" do
        Judoscale.configure { |config| config.test_job_config.enabled = false }

        run_loop_stub = proc do |config, metrics_collectors|
          _(metrics_collectors.size).must_equal 1
          _(metrics_collectors[0]).must_be_instance_of Test::TestWebMetricsCollector
        end

        Reporter.instance.stub(:run_loop, run_loop_stub) {
          Reporter.instance.start!(Config.instance, Judoscale.adapters)
        }
      end

      it "does not run the reporter thread when the API url is not configured" do
        Judoscale.configure { |config| config.api_base_url = nil }

        Reporter.instance.stub(:run_loop, ->(*) { raise "SHOULD NOT BE CALLED" }) {
          Reporter.instance.start!(Config.instance, Judoscale.adapters)
        }

        _(log_string).must_include "Reporter not started: JUDOSCALE_URL is not set"
      end

      it "does not run the reporter thread when there are no metrics collectors" do
        Reporter.instance.stub(:run_loop, ->(*) { raise "SHOULD NOT BE CALLED" }) {
          Reporter.instance.start!(Config.instance, Judoscale.adapters.select { |a| a.metrics_collector.nil? })
        }

        _(log_string).must_include "Reporter not started: no metrics need to be collected in this process"
      end

      it "logs when the reporter starts successfully" do
        stub_request(:post, "http://example.com/api/test-token/v3/reports")
        run_reporter_start_thread

        _(log_string).must_include "Reporter starting, will report every 10 seconds or so. Adapters: [judoscale-ruby, test_web, test_job]"
      end

      it "logs only enabled adapters" do
        Judoscale.configure { |config| config.test_job_config.enabled = false }

        stub_request(:post, "http://example.com/api/test-token/v3/reports")
        run_reporter_start_thread

        _(log_string).must_include "Reporter starting, will report every 10 seconds or so. Adapters: [judoscale-ruby, test_web]"
      end
    end

    describe "#run_metrics_collection" do
      it "collects and report metrics to the API" do
        web_metrics_collector = Test::TestWebMetricsCollector.new
        job_metrics_collector = Test::TestJobMetricsCollector.new
        all_metrics = web_metrics_collector.collect + job_metrics_collector.collect

        expected_body = Report.new(Judoscale.adapters, Config.instance, all_metrics).as_json
        stub = stub_request(:post, "http://example.com/api/test-token/v3/reports")
          .with(body: JSON.generate(expected_body))

        Reporter.instance.run_metrics_collection Config.instance, [web_metrics_collector, job_metrics_collector]

        assert_requested stub
      end

      it "logs reporting failures" do
        metrics_collector = Test::TestWebMetricsCollector.new

        stub_request(:post, %r{http://example.com/api/test-token/v3/reports})
          .to_return(body: "oops", status: 503)

        Reporter.instance.run_metrics_collection Config.instance, [metrics_collector]

        _(log_string).must_include "ERROR -- : [Judoscale] Reporter failed: 503 - "
      end

      it "logs exceptions when reporting collected information" do
        Reporter.instance.stub(:report, ->(*) { raise "REPORT BOOM!" }) {
          Reporter.instance.run_metrics_collection(Config.instance, [Test::TestWebMetricsCollector.new])
        }

        _(log_string).must_include "Reporter error: #<RuntimeError: REPORT BOOM!>"
        _(log_string).must_include "lib/judoscale/reporter.rb"
      end

      it "logs exceptions when collecting information, while still reporting other metrics successfully" do
        web_metrics_collector = Test::TestWebMetricsCollector.new
        job_metrics_collector = Test::TestJobMetricsCollector.new
        web_metrics = web_metrics_collector.collect

        expected_body = Report.new(Judoscale.adapters, Config.instance, web_metrics).as_json
        stub = stub_request(:post, "http://example.com/api/test-token/v3/reports")
          .with(body: JSON.generate(expected_body))

        job_metrics_collector.stub(:collect, ->(*) { raise "ADAPTER BOOM!" }) {
          Reporter.instance.run_metrics_collection(Config.instance, [web_metrics_collector, job_metrics_collector])
        }

        _(log_string).must_include "Reporter error: #<RuntimeError: ADAPTER BOOM!>"
        _(log_string).must_include "lib/judoscale/reporter.rb"
        assert_requested stub
      end
    end
  end
end
