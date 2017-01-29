require 'singleton'
require 'rails_autoscale_agent/autoscale_api'
require 'rails_autoscale_agent/time_rounder'

# Reporter wakes up every minute to send metrics to the RailsAutoscale API

module RailsAutoscaleAgent
  class Reporter
    include Singleton

    def self.start(config, store)
      instance.start!(config, store) unless instance.running?
    end

    def start!(config, store)
      puts "[rails-autoscale] [Reporter] [#{config}] starting reporter, will report every minute"

      @running = true

      Thread.new do
        loop do
          beginning_of_next_minute = TimeRounder.beginning_of_minute(Time.now) + 60

          # add 0-5 seconds to avoid slamming the API at one moment
          next_report_time = beginning_of_next_minute + rand * 5

          sleep next_report_time - Time.now

          begin
            report!(config, store)
          rescue => ex
            # Exceptions in threads other than the main thread will fail silently
            # https://ruby-doc.org/core-2.2.0/Thread.html#class-Thread-label-Exception+handling
            puts "[rails-autoscale] [Reporter] [#{config}] #{ex.inspect}"
            puts ex.backtrace.join("\n")
          end
        end
      end
    end

    def running?
      @running
    end

    def report!(config, store)
      while report = store.pop_report
        puts "[rails-autoscale] [Reporter] [#{config}] reporting queue times for #{report.values.size} requests during minute #{report.time.iso8601}"

        params = report.to_params(config)
        result = AutoscaleApi.new(config.api_base_url).report_metrics!(params)

        case result
        when AutoscaleApi::SuccessResponse
          puts "[rails-autoscale] [Reporter] [#{config}] reported successfully"
        when AutoscaleApi::FailureResponse
          puts "[rails-autoscale] [Reporter] [#{config}] failed: #{result.failure_message}"
        end
      end

      puts "[rails-autoscale] [Reporter] [#{config}] nothing to report" unless result
    end

  end
end
