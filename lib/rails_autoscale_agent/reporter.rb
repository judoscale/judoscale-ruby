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
      puts "[rails-autoscale] [Reporter] starting reporter, will report every #{config.report_interval} seconds"
      @running = true

      Thread.new do
        loop do
          sleep config.report_interval

          begin
            report!(config, store)
          rescue => ex
            # Exceptions in threads other than the main thread will fail silently
            # https://ruby-doc.org/core-2.2.0/Thread.html#class-Thread-label-Exception+handling
            puts "[rails-autoscale] [Reporter] #{ex.inspect}"
            puts ex.backtrace.join("\n")
          end
        end
      end
    end

    def running?
      @running
    end

    def report!(config, store)
      measurements = store.dump

      if measurements.any?
        measurements_by_minute = measurements.group_by { |qt| TimeRounder.beginning_of_minute(qt.time) }
        measurements_by_minute.each do |time, measurements|
          puts "[rails-autoscale] [Reporter] reporting queue times for #{measurements.size} requests during minute #{time.iso8601}"
          report_params = {
            time: time.iso8601,
            dyno: config.dyno,
            pid: config.pid,
            measurements: measurements.map(&:value),
          }

          result = AutoscaleApi.new(config.api_base_url).report_metrics!(report_params)

          case result
          when AutoscaleApi::SuccessResponse
            puts "[rails-autoscale] [Reporter] reported successfully"
          when AutoscaleApi::FailureResponse
            puts "[rails-autoscale] [Reporter] failed: #{result.failure_message}"
          end
        end
      else
        puts "[rails-autoscale] [Reporter] nothing to report"
      end
    end

  end
end
