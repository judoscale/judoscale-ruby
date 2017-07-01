require 'singleton'
require 'rails_autoscale_agent/time_rounder'
require 'rails_autoscale_agent/measurement'
require 'rails_autoscale_agent/report'

module RailsAutoscaleAgent
  class Store
    include Singleton

    def initialize
      @measurements = []
    end

    def push(value, time = Time.now)
      @measurements << Measurement.new(time, value)
    end

    def pop_report
      report = Report.new

      while measurement = @measurements.shift
        report.measurements << measurement
      end

      report
    end

  end
end
