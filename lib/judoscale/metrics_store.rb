# frozen_string_literal: true

require "singleton"
require "judoscale/metric"
require "judoscale/report"

module Judoscale
  class MetricsStore
    include Singleton

    attr_reader :metrics

    def initialize
      @metrics = []
      @last_pop = Time.now
    end

    def push(identifier, value, time = Time.now, queue_name = nil)
      # If it's been two minutes since clearing out the store, stop collecting metrics.
      # There could be an issue with the reporter, and continuing to collect will consume linear memory.
      return if @last_pop && @last_pop < Time.now - 120

      @metrics << Metric.new(identifier, time, value, queue_name)
    end

    def pop_report
      @last_pop = Time.now
      report = Report.new

      while (metric = @metrics.shift)
        report.metrics << metric
      end

      report
    end

    def clear
      @metrics.clear
    end
  end
end
