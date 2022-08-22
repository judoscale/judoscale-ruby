# frozen_string_literal: true

require "test_helper"
require "rails_autoscale/adapter_api"

describe RailsAutoscale::AdapterApi do
  let(:report_params) { {dyno: "web.1", metrics: [[Time.now.to_i, 11, "qt"], [Time.now.to_i, 33, "qt"]]} }
  let(:config) { Struct.new(:api_base_url).new("http://example.com") }

  describe "#report_metrics" do
    it "returns a successful response" do
      config.api_base_url = "http://railsautoscale.dev/api/test-app-token"
      stub = stub_request(:post, "http://railsautoscale.dev/api/test-app-token/v3/reports")
        .to_return(status: 200)

      adapter_api = RailsAutoscale::AdapterApi.new(config)
      result = adapter_api.report_metrics(report_params)

      _(result).must_be_instance_of RailsAutoscale::AdapterApi::SuccessResponse
      assert_requested stub
    end

    it "returns a failure response if we post unexpected params" do
      config.api_base_url = "http://railsautoscale.dev/api/bad-app-token"
      stub = stub_request(:post, "http://railsautoscale.dev/api/bad-app-token/v3/reports")
        .to_return(status: [400, "Bad Request"])

      adapter_api = RailsAutoscale::AdapterApi.new(config)
      result = adapter_api.report_metrics(report_params)

      _(result).must_be_instance_of RailsAutoscale::AdapterApi::FailureResponse
      _(result.failure_message).must_equal "400 - Bad Request"
      assert_requested stub
    end

    it "returns a failure response if the service is unavailable" do
      config.api_base_url = "http://does-not-exist.dev"
      stub = stub_request(:post, "http://does-not-exist.dev/v3/reports")
        .to_return(status: [503, "Service Unavailable"])

      adapter_api = RailsAutoscale::AdapterApi.new(config)
      result = adapter_api.report_metrics(report_params)

      _(result).must_be_instance_of RailsAutoscale::AdapterApi::FailureResponse
      _(result.failure_message).must_equal "503 - Service Unavailable"
      assert_requested stub
    end

    it "supports HTTPS" do
      config.api_base_url = "https://rails-autoscale-production.herokuapp.com/api/test-token"
      stub = stub_request(:post, "https://rails-autoscale-production.herokuapp.com/api/test-token/v3/reports")
        .to_return(status: 200)

      adapter_api = RailsAutoscale::AdapterApi.new(config)
      result = adapter_api.report_metrics(report_params)

      _(result).must_be_instance_of RailsAutoscale::AdapterApi::SuccessResponse
      assert_requested stub
    end
  end
end
