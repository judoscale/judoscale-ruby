require 'singleton'

module RailsAutoscaleAgent
  class Config
    include Singleton

    attr_reader :api_base_url, :dyno, :pid, :fake_mode, :max_request_size
    attr_accessor :report_interval
    alias_method :fake_mode?, :fake_mode

    def initialize
      @api_base_url = ENV['RAILS_AUTOSCALE_URL']
      @pid = Process.pid
      @max_request_size = 100_000 # ignore request payloads over 100k since they skew the queue times
      @report_interval = 60 # this default will be overwritten during Reporter#register!
      @fake_mode = true if ENV['RAILS_AUTOSCALE_FAKE_MODE'] == 'true'

      if fake_mode?
        @dyno = 'web.123'
      else
        @dyno = ENV['DYNO']
      end
    end

    def to_s
      "#{@dyno}##{@pid}"
    end

    def ignore_large_requests?
      @max_request_size.present?
    end

  end
end
