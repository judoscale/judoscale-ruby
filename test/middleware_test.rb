# frozen_string_literal: true

require "test_helper"
require "judoscale/middleware"

module Judoscale
  class MockApp
    attr_reader :env

    def call(env)
      @env = env
      nil
    end
  end

  describe Middleware do
    describe "#call" do
      before { Reporter.instance.instance_variable_set("@running", nil) }
      after { Store.instance.instance_variable_set "@measurements", [] }

      let(:app) { MockApp.new }
      let(:env) {
        {
          "PATH_INFO" => "/foo",
          "REQUEST_METHOD" => "POST",
          "rack.input" => StringIO.new("hello")
        }
      }
      let(:middleware) { Middleware.new(app) }

      describe "with JUDOSCALE_URL set" do
        def setup
          use_env({"JUDOSCALE_URL" => "http://example.com"}) do
            super
          end
        end

        it "passes the request up the middleware stack" do
          middleware.call(env)
          _(app.env).must_equal(env)
        end

        it "starts the reporter" do
          middleware.call(env)
          _(Reporter.instance).must_be :started?
        end

        describe "when the request includes HTTP_X_REQUEST_START" do
          let(:five_seconds_ago_in_unix_millis) { (Time.now.to_f - 5) * 1000 }

          before { env["HTTP_X_REQUEST_START"] = five_seconds_ago_in_unix_millis.to_i.to_s }
          after { Store.instance.instance_variable_set "@measurements", [] }

          it "collects the request queue time" do
            middleware.call(env)

            report = Store.instance.pop_report
            _(report.measurements.length).must_equal 1
            _(report.measurements.first).must_be_instance_of Measurement
            _(report.measurements.first.value).must_be_within_delta 5000, 1
          end

          it "records the queue time in the environment passed on" do
            middleware.call(env)

            _(app.env).must_include("queue_time")
            _(app.env["queue_time"]).must_be_within_delta 5000, 1
          end

          describe "when the request body is large enough to skew the queue time" do
            before { env["rack.input"] = StringIO.new("." * 110_000) }

            it "does not collect the request queue time" do
              middleware.call(env)

              report = Store.instance.pop_report
              _(report.measurements.length).must_equal 0
            end
          end
        end
      end

      describe "without JUDOSCALE_URL set" do
        def setup
          use_env({"JUDOSCALE_URL" => nil}) do
            super
          end
        end

        it "passes the request up the middleware stack" do
          middleware.call(env)
          _(app.env).must_equal env
        end

        it "does not start the reporter" do
          Reporter.instance.stub(:register!, -> { raise "NEVER CALLED" }) do
            middleware.call(env)
          end
        end
      end
    end
  end
end
