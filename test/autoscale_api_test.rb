# frozen_string_literal: true

require "test_helper"
require "judoscale/autoscale_api"

describe Judoscale::AutoscaleApi, vcr: {record: :once} do
  let(:measurements_csv) { "#{Time.now.to_i},11\n#{Time.now.to_i},33\n" }
  let(:config) { Struct.new(:api_base_url, :dev_mode).new("http://example.com", false) }

  describe "#report_metrics!" do
    it "returns a successful response" do
      config.api_base_url = "http://judoscale.dev/api/test-app-token"
      report_params = {
        dyno: "web.1",
        pid: "1232"
      }
      autoscale_api = Judoscale::AutoscaleApi.new(config)
      result = autoscale_api.report_metrics!(report_params, measurements_csv)

      _(result).must_be_instance_of Judoscale::AutoscaleApi::SuccessResponse
    end

    it "returns a failure response if we post unexpected params" do
      config.api_base_url = "http://judoscale.dev/api/bad-app-token"
      autoscale_api = Judoscale::AutoscaleApi.new(config)
      result = autoscale_api.report_metrics!({}, measurements_csv)

      _(result).must_be_instance_of Judoscale::AutoscaleApi::FailureResponse
      _(result.failure_message).must_equal "400 - Bad Request"
    end

    it "returns a failure response if the service is unavailable" do
      config.api_base_url = "http://does-not-exist.dev"
      autoscale_api = Judoscale::AutoscaleApi.new(config)
      result = autoscale_api.report_metrics!([], measurements_csv)

      _(result).must_be_instance_of Judoscale::AutoscaleApi::FailureResponse
      _(result.failure_message).must_equal "503 - Service Unavailable"
    end

    it "supports HTTPS" do
      config.api_base_url = "https://judoscale-production.herokuapp.com/api/test-token"
      report_params = {
        dyno: "web.1",
        pid: "1232"
      }

      autoscale_api = Judoscale::AutoscaleApi.new(config)
      result = autoscale_api.report_metrics!(report_params, measurements_csv)

      _(result).must_be_instance_of Judoscale::AutoscaleApi::SuccessResponse
    end
  end

  describe "#register_reporter!" do
    it "returns a successful response" do
      config.api_base_url = "http://judoscale.dev/api/test-app-token"
      registration_params = {
        pid: "1232"
      }
      autoscale_api = Judoscale::AutoscaleApi.new(config)
      result = autoscale_api.register_reporter!(registration_params)

      _(result).must_be_instance_of Judoscale::AutoscaleApi::SuccessResponse
    end
  end
end
