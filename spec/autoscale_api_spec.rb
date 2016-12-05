require 'spec_helper'
require 'vcr'
require 'rails_autoscale_agent/autoscale_api'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

describe RailsAutoscaleAgent::AutoscaleApi, :vcr do

  describe "#report_metrics!" do
    it 'returns a successful response' do
      api_base = 'http://rails-autoscale.dev/api/test-app-token'
      metrics_params = [
        {
          time: '2016-12-03T01:22:00+00:00',
          type: RailsAutoscaleAgent::WAIT_TIME_TYPE,
          dyno: 'web.1',
          values: [11, 33],
        },
      ]

      autoscale_api = RailsAutoscaleAgent::AutoscaleApi.new(api_base)
      result = autoscale_api.report_metrics!(metrics_params)

      expect(result).to be_a RailsAutoscaleAgent::AutoscaleApi::SuccessResponse
    end

    it 'returns a failure response if we pass a bad token' do
      api_base = 'http://rails-autoscale.dev/api/bad-app-token'
      autoscale_api = RailsAutoscaleAgent::AutoscaleApi.new(api_base)
      result = autoscale_api.report_metrics!([])

      expect(result).to be_a RailsAutoscaleAgent::AutoscaleApi::FailureResponse
      expect(result.failure_message).to eql 'Unauthorized'
    end

    it 'returns a failure response if the service is unavailable' do
      autoscale_api = RailsAutoscaleAgent::AutoscaleApi.new('http://does-not-exist.dev')
      result = autoscale_api.report_metrics!([])

      expect(result).to be_a RailsAutoscaleAgent::AutoscaleApi::FailureResponse
      expect(result.failure_message).to eql 'Service Unavailable'
    end

    it 'returns a failure response if we post bad data'
  end

end
