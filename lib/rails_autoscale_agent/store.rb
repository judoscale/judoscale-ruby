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
      @last_pop = Time.now
    end

    def push(value, time = Time.now, queue_name = nil, metric = nil)
      # If it's been two minutes since clearing out the store, stop collecting measurements.
      # There could be an issue with the reporter, and continuing to collect will consume linear memory.
      return if @last_pop && @last_pop < Time.now - 120

      @measurements << Measurement.new(time, value, queue_name, metric)
    end

    def pop_report
      @last_pop = Time.now
      report = Report.new

      while measurement = @measurements.shift
        report.measurements << measurement
      end

      report
    end

  end
end
