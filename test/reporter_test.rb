# frozen_string_literal: true

require "test_helper"
require "judoscale/reporter"
require "judoscale/config"
require "judoscale/store"

module Judoscale
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

      def run_reporter_start_thread
        stub_reporter_loop {
          reporter_thread = Reporter.instance.start!(Config.instance, Store.instance)
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

      it "logs exceptions when collecting adapter information" do
        enabled_adapter = WorkerAdapters.load_adapters(Config.instance.worker_adapters).find(&:enabled?)
        _(enabled_adapter).wont_be :nil?

        enabled_adapter.stub(:collect!, ->(*) { raise "ADAPTER BOOM!" }) {
          run_reporter_start_thread
        }

        _(log_string).must_include "Reporter error: #<RuntimeError: ADAPTER BOOM!>"
        _(log_string).must_include "lib/judoscale/reporter.rb"
      end
    end

    describe "#report!" do
      after { Store.instance.clear }

      it "reports stored metrics to the API" do
        store = Store.instance

        expected_query = {dyno: "web.1", pid: Process.pid}
        expected_body = "1000000001,11,,qt\n1000000002,22,high,qt\n"
        stub = stub_request(:post, "http://example.com/api/test-token/v2/reports")
          .with(query: expected_query, body: expected_body)

        store.push :qt, 11, Time.at(1_000_000_001) # web measurement
        store.push :qt, 22, Time.at(1_000_000_002), "high" # worker measurement

        Reporter.instance.send :report!, Config.instance, store

        assert_requested stub
      end

      it "logs reporter failures" do
        store = Store.instance
        stub_request(:post, %r{http://example.com/api/test-token/v2/reports})
          .to_return(body: "oops", status: 503)

        store.push :qt, 1, Time.at(1_000_000_001) # need some measurement to trigger reporting

        log_io = StringIO.new
        stub_logger = ::Logger.new(log_io)

        Reporter.instance.stub(:logger, stub_logger) {
          Reporter.instance.send :report!, Config.instance, store
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
            worker_adapters: ""
          }
        }
        response = {}.to_json
        stub = stub_request(:post, "http://example.com/api/test-token/registrations")
          .with(body: expected_body)
          .to_return(body: response)

        Reporter.instance.send :register!, Config.instance, []

        assert_requested stub
      end
    end
  end
end
