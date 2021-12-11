# frozen_string_literal: true

require 'spec_helper'
require 'judoscale/middleware'

module Judoscale
  describe Middleware do

    class MockApp
      attr_reader :env

      def call(env)
        @env = env
        nil
      end
    end

    describe "#call" do
      before { Reporter.instance.instance_variable_set('@running', nil) }

      let(:app) { MockApp.new }
      let(:env) { {
        'PATH_INFO' => '/foo',
        'REQUEST_METHOD' => 'POST',
        'rack.input' => StringIO.new('hello'),
      } }
      let(:middleware) { Middleware.new(app) }

      context "with JUDOSCALE_URL set" do
        around { |example| use_env({'JUDOSCALE_URL' => 'http://example.com'}, &example) }

        it "passes the request up the middleware stack" do
          middleware.call(env)
          expect(app.env).to include(env)
        end

        it "starts the reporter" do
          middleware.call(env)
          expect(Reporter.instance).to be_started
        end

        context "when the request includes HTTP_X_REQUEST_START" do
          let(:five_seconds_ago_in_unix_millis) { (Time.now.to_f - 5) * 1000 }
          before { env['HTTP_X_REQUEST_START'] = five_seconds_ago_in_unix_millis.to_i.to_s }
          before { Singleton.__init__(Store) }

          it "collects the request queue time" do
            middleware.call(env)

            report = Store.instance.pop_report
            expect(report.measurements.length).to eql 1
            expect(report.measurements.first).to be_a Measurement
            expect(report.measurements.first.value).to be_within(1).of(5000)
          end

          it "records the queue time in the environment passed on" do
            middleware.call(env)

            expect(app.env).to have_key("queue_time")
            expect(app.env["queue_time"]).to be_within(1).of(5000)
          end

          context "when the request body is large enough to skew the queue time" do
            before { env['rack.input'] = StringIO.new('.'*110_000) }

            it "does not collect the request queue time" do
              middleware.call(env)

              report = Store.instance.pop_report
              expect(report.measurements.length).to eql 0
            end
          end
        end
      end

      context "without JUDOSCALE_URL set" do
        around { |example| use_env({'JUDOSCALE_URL' => nil}, &example) }

        it "passes the request up the middleware stack" do
          middleware.call(env)
          expect(app.env).to include(env)
        end

        it "does not start the reporter" do
          allow(Reporter.instance).to receive(:register!)
          middleware.call(env)
          expect(Reporter.instance).to_not have_received(:register!)
        end
      end
    end

  end
end
