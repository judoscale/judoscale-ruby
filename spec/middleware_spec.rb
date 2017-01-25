require 'spec_helper'
require 'rails_autoscale_agent/middleware'

module RailsAutoscaleAgent
  describe Middleware do

    describe "#call" do
      before { Reporter.instance.instance_variable_set('@running', nil) }

      let(:app) { double(:app, call: nil) }
      let(:env) { {} }
      let(:middleware) { Middleware.new(app) }

      context "with RAILS_AUTOSCALE_URL set" do
        before { ENV['RAILS_AUTOSCALE_URL'] = 'http://example.com' }

        it "passes the request up the middleware stack" do
          middleware.call(env)
          expect(app).to have_received(:call).with(env)
        end

        it "starts the reporter" do
          middleware.call(env)
          expect(Reporter.instance).to be_running
        end

        context "when the request includes HTTP_X_REQUEST_START" do
          let(:five_seconds_ago_in_unix_millis) { (Time.now.to_f - 5) * 1000 }
          let(:env) { {'HTTP_X_REQUEST_START' => five_seconds_ago_in_unix_millis } }

          it "stores the request wait time" do
            store = Store.instance

            store.instance_variable_set '@measurements', []
            middleware.call(env)
            measurements = store.instance_variable_get('@measurements')

            expect(measurements.length).to eql 1
            expect(measurements.first).to be_a Measurement
            expect(measurements.first.value).to eql 5000
          end
        end
      end

      context "without RAILS_AUTOSCALE_URL set" do
        before { ENV['RAILS_AUTOSCALE_URL'] = nil }

        it "passes the request up the middleware stack" do
          middleware.call(env)
          expect(app).to have_received(:call).with(env)
        end

        it "does not start the reporter" do
          middleware.call(env)
          expect(Reporter.instance).to_not be_running
        end
      end
    end

  end
end
