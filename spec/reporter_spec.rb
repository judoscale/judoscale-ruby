# frozen_string_literal: true

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

        expected_query = { dyno: 'web.0', pid: Process.pid }
        expected_body = /1000000001,11,,\n1000000002,22,high,\n\d+,0,,\n/
        stub = stub_request(:post, "http://example.com/api/test-token/v2/reports").
                 with(query: expected_query, body: expected_body)

        store.push 11, Time.at(1_000_000_001) # web measurement
        store.push 22, Time.at(1_000_000_002), 'high' # worker measurement

        Reporter.instance.send :report!, Config.instance, store

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
            gem_version: RailsAutoscaleAgent::VERSION,
            worker_adapters: '',
          }
        }
        response = {report_interval: 123}.to_json
        stub = stub_request(:post, "http://example.com/api/test-token/registrations").
                 with(body: expected_body).
                 to_return(body: response)

        Reporter.instance.send :register!, Config.instance, []

        expect(stub).to have_been_requested.once
      end
    end

  end
end
