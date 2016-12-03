require 'net/http'
require 'uri'
require 'json'

module RailsAutoscaleAgent
  class AutoscaleApi

    SUCCESS = 'success'
    API_BASE_PATH = '/api'

    def initialize(api_url_base)
      @api_url_base = api_url_base
    end

    def report_metrics!(metrics)
      post '/reports', report: metrics
    end

    private

    def post(path, data)
      header = {'Content-Type' => 'application/json'}
      uri = URI.parse("#{@api_url_base}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.request_uri, header)

      request.body = JSON.dump(data)

      puts "[rails-autoscale] [AutoscaleApi] Posting to #{request.body.size} bytes to #{uri}"
      response = http.request(request)

      case response.code.to_i
      when 200...300 then SuccessResponse.new
      else FailureResponse.new(response.message)
      end
    end

    class SuccessResponse
    end

    class FailureResponse < Struct.new(:failure_message)
    end

  end
end