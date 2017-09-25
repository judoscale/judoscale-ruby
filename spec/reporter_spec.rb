require 'spec_helper'
require 'rails_autoscale_agent/reporter'
require 'rails_autoscale_agent/config'
require 'rails_autoscale_agent/store'
require 'webmock/rspec'

module RailsAutoscaleAgent
  describe Reporter do

    around do |example|
      use_env({
        'DYNO' => 'web.0',
        'RAILS_AUTOSCALE_URL' => 'http://example.com/api/test-token',
      }, &example)
    end

    describe "#report!" do
      it "reports stored metrics to the API" do
        store = Store.instance
        store.instance_variable_set '@measurements', []

        measurement_time = Time.now - 5
        measurement_value = 123
        query = { dyno: 'web.0', pid: Process.pid }
        body = "#{measurement_time.to_i},#{measurement_value}\n"
        stub = stub_request(:post, "http://example.com/api/test-token/v2/reports").
                 with(query: query, body: body)

        store.push measurement_value, measurement_time

        Reporter.instance.report!(Config.instance, store)

        expect(stub).to have_been_requested.once
      end
    end

    describe "#register!" do
      it "registers the reporter with contextual info" do
        expected_body = {
          registration: {
            dyno: 'web.0',
            pid: Process.pid,
            ruby_version: RUBY_VERSION,
            rails_version: '5.0.fake',
            gem_version: '0.3.0',
          }
        }
        response = {report_interval: 123}.to_json
        stub = stub_request(:post, "http://example.com/api/test-token/registrations").
                 with(body: expected_body).
                 to_return(body: response)

        Reporter.instance.register!(Config.instance)

        expect(stub).to have_been_requested.once
      end
    end

  end
end
