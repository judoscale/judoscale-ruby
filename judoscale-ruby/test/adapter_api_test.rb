# frozen_string_literal: true

require "test_helper"
require "judoscale/adapter_api"

describe Judoscale::AdapterApi do
  let(:report_params) { {dyno: "web.1", metrics: [[Time.now.to_i, 11, "qt"], [Time.now.to_i, 33, "qt"]]} }
  let(:config) { Struct.new(:api_base_url).new("http://example.com") }

  describe "#report_metrics!" do
    it "returns a successful response" do
      config.api_base_url = "http://judoscale.dev/api/test-app-token"
      stub = stub_request(:post, "http://judoscale.dev/api/test-app-token/v1/metrics")
        .to_return(status: 200)

      adapter_api = Judoscale::AdapterApi.new(config)
      result = adapter_api.report_metrics!(report_params)

      _(result).must_be_instance_of Judoscale::AdapterApi::SuccessResponse
      assert_requested stub
    end

    it "returns a failure response if we post unexpected params" do
      config.api_base_url = "http://judoscale.dev/api/bad-app-token"
      stub = stub_request(:post, "http://judoscale.dev/api/bad-app-token/v1/metrics")
        .to_return(status: [400, "Bad Request"])

      adapter_api = Judoscale::AdapterApi.new(config)
      result = adapter_api.report_metrics!(report_params)

      _(result).must_be_instance_of Judoscale::AdapterApi::FailureResponse
      _(result.failure_message).must_equal "400 - Bad Request"
      assert_requested stub
    end

    it "returns a failure response if the service is unavailable" do
      config.api_base_url = "http://does-not-exist.dev"
      stub = stub_request(:post, "http://does-not-exist.dev/v1/metrics")
        .to_return(status: [503, "Service Unavailable"])

      adapter_api = Judoscale::AdapterApi.new(config)
      result = adapter_api.report_metrics!(report_params)

      _(result).must_be_instance_of Judoscale::AdapterApi::FailureResponse
      _(result.failure_message).must_equal "503 - Service Unavailable"
      assert_requested stub
    end

    it "supports HTTPS" do
      config.api_base_url = "https://judoscale-production.herokuapp.com/api/test-token"
      stub = stub_request(:post, "https://judoscale-production.herokuapp.com/api/test-token/v1/metrics")
        .to_return(status: 200)

      adapter_api = Judoscale::AdapterApi.new(config)
      result = adapter_api.report_metrics!(report_params)

      _(result).must_be_instance_of Judoscale::AdapterApi::SuccessResponse
      assert_requested stub
    end
  end
end
