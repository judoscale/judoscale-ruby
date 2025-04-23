# frozen_string_literal: true

require "test_helper"
require "judoscale/request_middleware"

module Judoscale
  class MockApp
    attr_reader :env

    def call(env)
      @env = env
      self
    end
  end

  describe RequestMiddleware do
    describe "#call" do
      after {
        Reporter.instance.stop!
        MetricsStore.instance.clear
      }

      let(:app) { MockApp.new }
      let(:env) {
        {
          "PATH_INFO" => "/foo",
          "REQUEST_METHOD" => "POST",
          "rack.input" => StringIO.new("hello")
        }
      }
      let(:middleware) { RequestMiddleware.new(app) }

      describe "with the API URL configured" do
        before {
          Judoscale.configure { |config| config.api_base_url = "http://example.com" }
        }

        it "passes the request env up the middleware stack, returning the app's response" do
          response = middleware.call(env)

          _(response).must_equal app
          _(app.env).must_equal env
        end

        it "starts the reporter" do
          middleware.call(env)
          _(Reporter.instance).must_be :started?
        end

        describe "when the request includes HTTP_X_REQUEST_START" do
          let(:now) { Time.now.utc }
          let(:five_seconds_ago_in_unix_millis) { (now.to_f - 5) * 1000 }

          before { env["HTTP_X_REQUEST_START"] = five_seconds_ago_in_unix_millis.to_i.to_s }
          after { MetricsStore.instance.clear }

          it "collects the request queue time and application time" do
            freeze_time now do
              middleware.call(env)
            end

            metrics = MetricsStore.instance.flush
            _(metrics.length).must_equal 2
            _(metrics[0]).must_be_instance_of Metric
            _(metrics[0].value).must_be_within_delta 5000, 1
            _(metrics[0].identifier).must_equal :qt
            _(metrics[1]).must_be_instance_of Metric
            _(metrics[1].value).must_be_within_delta 0, 0.1
            _(metrics[1].identifier).must_equal :at
          end

          it "records the queue time in the environment passed on" do
            freeze_time now do
              middleware.call(env)
            end

            _(app.env).must_include("judoscale.queue_time")
            _(app.env["judoscale.queue_time"]).must_be_within_delta 5000, 1
          end

          it "logs debug information about the request and queue time" do
            use_config log_level: :debug do
              env["HTTP_X_REQUEST_ID"] = "req-abc-123"

              middleware.call(env)

              _(log_string).must_match %r{Request queue_time=500\dms network_time=0ms request_id=req-abc-123 size=5}
            end
          end

          describe "when the request body is large enough to skew the queue time" do
            before { env["rack.input"] = StringIO.new("." * 110_000) }

            it "does not collect the request queue time" do
              middleware.call(env)

              metrics = MetricsStore.instance.flush
              _(metrics.length).must_equal 1
              _(metrics[0].identifier).must_equal :at
            end
          end

          describe "when Puma request body wait / network time is available" do
            before { env["puma.request_body_wait"] = 50 }

            it "collects the request network time as a separate metric" do
              middleware.call(env)

              metrics = MetricsStore.instance.flush
              _(metrics.length).must_equal 3
              _(metrics[1]).must_be_instance_of Metric
              _(metrics[1].value).must_equal 50
              _(metrics[1].identifier).must_equal :nt
            end

            it "records the network time in the environment passed on" do
              middleware.call(env)

              _(app.env).must_include("judoscale.network_time")
              _(app.env["judoscale.network_time"]).must_equal 50
            end
          end
        end
      end

      describe "without the API URL configured" do
        before {
          Judoscale.configure { |config| config.api_base_url = nil }
        }

        it "passes the request up the middleware stack" do
          middleware.call(env)
          _(app.env).must_equal env
        end

        it "does not start the reporter" do
          Thread.stub(:new, -> { raise "SHOULD NOT BE CALLED" }) do
            middleware.call(env)
          end
        end
      end
    end
  end
end
