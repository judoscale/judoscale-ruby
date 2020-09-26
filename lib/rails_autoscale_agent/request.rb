# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  class Request
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
        # Heroku sets the header as an integer, measured in milliseconds.
        # If nginx is involved, it might be in seconds with fractional milliseconds,
        # and it might be preceeded by "t=". We can all cases by removing non-digits
        # and treating as milliseconds.
        Time.at(@request_start_header.gsub(/\D/, '').to_i / 1000.0)
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
