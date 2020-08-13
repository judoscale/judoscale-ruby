# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/middleware'

module RailsAutoscaleAgent
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

      context "with RAILS_AUTOSCALE_URL set" do
        around { |example| use_env({'RAILS_AUTOSCALE_URL' => 'http://example.com'}, &example) }

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
          before { env['HTTP_X_REQUEST_START'] = five_seconds_ago_in_unix_millis }
          before { Singleton.__init__(Store) }

          it "collects the request queue time" do
            middleware.call(env)

            report = Store.instance.pop_report
            expect(report.measurements.length).to eql 2
            expect(report.measurements.first).to be_a Measurement
            expect(report.measurements.first.value).to be_within(1).of(5000)
            expect(report.measurements.last.value).to eq 0
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

              # The default 0ms metric is still collected
              expect(report.measurements.length).to eql 1
              expect(report.measurements.last.value).to eq 0
            end
          end
        end
      end

      context "without RAILS_AUTOSCALE_URL set" do
        around { |example| use_env({'RAILS_AUTOSCALE_URL' => nil}, &example) }

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
