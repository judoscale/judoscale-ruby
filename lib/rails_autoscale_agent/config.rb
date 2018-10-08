require 'singleton'

module RailsAutoscaleAgent
  class Config
    include Singleton

    attr_accessor :report_interval, :logger, :api_base_url, :max_request_size,
                  :dyno, :pid

    def initialize
      @api_base_url = ENV['RAILS_AUTOSCALE_URL']
      @pid = Process.pid
      @max_request_size = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval = 60 # this default will be overwritten during Reporter#register!
      @logger ||= defined?(Rails) ? Rails.logger : ::Logger.new(STDOUT)
      @dyno = ENV['DYNO']
    end

    def to_s
      "#{@dyno}##{@pid}"
    end

    def ignore_large_requests?
      @max_request_size
    end

  end
end
