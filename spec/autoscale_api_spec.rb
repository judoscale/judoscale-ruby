require 'spec_helper'
require 'vcr'
require 'rails_autoscale_agent/autoscale_api'

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.configure_rspec_metadata!
end

describe RailsAutoscaleAgent::AutoscaleApi, vcr: {record: :once} do

  let(:measurements_csv) { "#{Time.now.to_i},11\n#{Time.now.to_i},33\n" }

  describe "#report_metrics!" do
    it 'returns a successful response' do
      api_base = 'http://rails-autoscale.dev/api/test-app-token'
      report_params = {
        dyno: 'web.1',
        pid: '1232',
      }
      autoscale_api = RailsAutoscaleAgent::AutoscaleApi.new(api_base)
      result = autoscale_api.report_metrics!(report_params, measurements_csv)

      expect(result).to be_a RailsAutoscaleAgent::AutoscaleApi::SuccessResponse
    end

    it 'returns a failure response if we post unexpected params' do
      api_base = 'http://rails-autoscale.dev/api/bad-app-token'
      autoscale_api = RailsAutoscaleAgent::AutoscaleApi.new(api_base)
      result = autoscale_api.report_metrics!({}, measurements_csv)

      expect(result).to be_a RailsAutoscaleAgent::AutoscaleApi::FailureResponse
      expect(result.failure_message).to eql 'Bad Request'
    end

    it 'returns a failure response if the service is unavailable' do
      autoscale_api = RailsAutoscaleAgent::AutoscaleApi.new('http://does-not-exist.dev')
      result = autoscale_api.report_metrics!([], measurements_csv)

      expect(result).to be_a RailsAutoscaleAgent::AutoscaleApi::FailureResponse
      expect(result.failure_message).to eql 'Service Unavailable'
    end

    it 'supports HTTPS' do
      api_base = 'https://rails-autoscale-production.herokuapp.com/api/test-token'
      report_params = {
        dyno: 'web.1',
        pid: '1232',
      }

      autoscale_api = RailsAutoscaleAgent::AutoscaleApi.new(api_base)
      result = autoscale_api.report_metrics!(report_params, measurements_csv)

      expect(result).to be_a RailsAutoscaleAgent::AutoscaleApi::SuccessResponse
    end
  end

  describe "#register_reporter!" do
    it 'returns a successful response' do
      api_base = 'http://rails-autoscale.dev/api/test-app-token'
      registration_params = {
        dyno: 'web.1',
        pid: '1232',
      }
      autoscale_api = RailsAutoscaleAgent::AutoscaleApi.new(api_base)
      result = autoscale_api.register_reporter!(registration_params)

      expect(result).to be_a RailsAutoscaleAgent::AutoscaleApi::SuccessResponse
    end
  end

end
