require 'net/http'
require 'uri'
require 'json'

module RailsAutoscaleAgent
  class AutoscaleApi

    SUCCESS = 'success'

    def initialize(api_url_base)
      @api_url_base = api_url_base
    end

    def report_metrics!(report_params)
      post '/reports', report: report_params
    end

    private

    def post(path, data)
      header = {'Content-Type' => 'application/json'}
      uri = URI.parse("#{@api_url_base}#{path}")
      ssl = uri.scheme == 'https'

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: ssl) do |http|
        request = Net::HTTP::Post.new(uri.request_uri, header)
        request.body = JSON.dump(data)

        puts "[rails-autoscale] [AutoscaleApi] Posting to #{request.body.size} bytes to #{uri}"
        http.request(request)
      end

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
