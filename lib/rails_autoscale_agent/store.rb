require 'singleton'
require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/time_rounder'
require 'rails_autoscale_agent/measurement'
require 'rails_autoscale_agent/report'

module RailsAutoscaleAgent
  class Store
    include Singleton
    include Logger

    def initialize
      @measurements = []
    end

    def push(value, time = Time.now)
      logger.debug "[Collector] queue time: #{value}"
      @measurements << Measurement.new(time, value)
    end

    def pop_report
      result = nil
      boundary = TimeRounder.beginning_of_minute(Time.now)

      while @measurements[0] && @measurements[0].time < boundary
        measurement = @measurements.shift

        if result.nil?
          report_time = TimeRounder.beginning_of_minute(measurement.time)
          boundary = report_time + 60
          result = Report.new(report_time)
        end

        result.values << measurement.value
      end

      result
    end

  end
end
