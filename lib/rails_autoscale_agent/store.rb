# frozen_string_literal: true

require 'singleton'
require 'rails_autoscale_agent/time_rounder'
require 'rails_autoscale_agent/measurement'
require 'rails_autoscale_agent/report'

module RailsAutoscaleAgent
  class Store
    include Singleton

    attr_reader :measurements

    def initialize
      @measurements = []
    end

    def push(value, time = Time.now, queue_name = nil, metric = nil)
      @measurements << Measurement.new(time, value, queue_name, metric)
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
