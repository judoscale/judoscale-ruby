# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  class Request
    # A request start time before a day ago would be unreasonable, and we must be
    # interpreting the header incorrectly.
    MINIMUM_REQUEST_START = Time.now - 60 * 60 * 24

    include Logger

    def initialize(env, config)
      @config = config
      @id = env['HTTP_X_REQUEST_ID']
      @size = env['rack.input'].respond_to?(:size) ? env['rack.input'].size : 0
      @request_body_wait = env['puma.request_body_wait'].to_i
      @request_start_header = env['HTTP_X_REQUEST_START']
    end

    def ignore?
      @config.ignore_large_requests? && @size > @config.max_request_size
    end

    def started_at
      if @request_start_header
        request_start_header = @request_start_header.to_f
        # If Heroku set the header, it's measured in milliseconds
        started_at = Time.at(request_start_header / 1000)

        # But if this app is using an nginx buildpack, it might be in seconds
        started_at = Time.at(request_start_header) if started_at < MINIMUM_REQUEST_START

        started_at
      elsif @config.dev_mode?
        # In dev mode, fake a queue time of 0-1000ms
        Time.now - rand + @request_body_wait
      end
    end

    def queue_time(now = Time.now)
      return if started_at.nil?

      queue_time = ((now - started_at) * 1000).to_i

      # Subtract the time Puma spent waiting on the request body. It's irrelevant to capacity-related queue time.
      # Without this, slow clients and large request payloads will skew queue time.
      queue_time -= @request_body_wait

      logger.debug "Request queue_time=#{queue_time}ms body_wait=#{@request_body_wait}ms request_id=#{@id} size=#{@size}"

      # Safeguard against negative queue times (should not happen in practice)
      queue_time > 0 ? queue_time : 0
    end
  end
end
