require 'singleton'
require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/autoscale_api'
require 'rails_autoscale_agent/time_rounder'

# Reporter wakes up every minute to send metrics to the RailsAutoscale API

module RailsAutoscaleAgent
  class Reporter
    include Singleton
    include Logger

    def self.start(config, store)
      instance.start!(config, store) unless instance.running?
    end

    def start!(config, store)
      logger.debug "[Reporter] starting reporter, will report every minute"

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
            logger.debug "[Reporter] #{ex.inspect}"
            logger.debug ex.backtrace.join("\n")
          end
        end
      end
    end

    def running?
      @running
    end

    def report!(config, store)
      while report = store.pop_report
        logger.debug "[Reporter] reporting queue times for #{report.values.size} requests during minute #{report.time.iso8601}"

        params = report.to_params(config)
        result = AutoscaleApi.new(config.api_base_url).report_metrics!(params)

        case result
        when AutoscaleApi::SuccessResponse
          logger.debug "[Reporter] reported successfully"
        when AutoscaleApi::FailureResponse
          logger.debug "[Reporter] failed: #{result.failure_message}"
        end
      end

      logger.debug "[Reporter] nothing to report" unless result
    end

  end
end
