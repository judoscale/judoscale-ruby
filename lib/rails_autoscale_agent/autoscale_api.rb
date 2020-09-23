# frozen_string_literal: true

require 'net/http'
require 'uri'
require 'json'
require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  class AutoscaleApi
    include Logger

    SUCCESS = 'success'

    def initialize(config)
      @config = config
    end

    def report_metrics!(report_params, timings_csv)
      query = URI.encode_www_form(report_params)
      post_csv "/v2/reports?#{query}", timings_csv
    end

    def register_reporter!(registration_params)
      post_json '/registrations', registration: registration_params
    end

    def report_exception!(ex)
      post_json '/exceptions', message: ex.inspect, backtrace: ex.backtrace.join("\n")
    end

    private

    def post_json(path, data)
      headers = {'Content-Type' => 'application/json'}
      post_raw path: path, body: JSON.dump(data), headers: headers
    end

    def post_csv(path, data)
      headers = {'Content-Type' => 'text/csv'}
      post_raw path: path, body: data, headers: headers
    end

    def post_raw(options)
      uri = URI.parse("#{@config.api_base_url}#{options.fetch(:path)}")
      ssl = uri.scheme == 'https'

      if @config.dev_mode
        logger.debug "[DEV_MODE] Skipping request to #{uri}"
        return SuccessResponse.new('{}')
      end

      response = Net::HTTP.start(uri.host, uri.port, use_ssl: ssl) do |http|
        request = Net::HTTP::Post.new(uri.request_uri, options[:headers] || {})
        request.body = options.fetch(:body)

        logger.debug "Posting #{request.body.size} bytes to #{uri}"
        http.request(request)
      end

      case response.code.to_i
      when 200...300 then SuccessResponse.new(response.body)
      else FailureResponse.new([response.code, response.message].join(' - '))
      end
    end

    class SuccessResponse < Struct.new(:body)
      def data
        JSON.parse(body)
      rescue TypeError
        {}
      end
    end

    class FailureResponse < Struct.new(:failure_message)
    end

  end
end
