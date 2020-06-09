# frozen_string_literal: true

module RailsAutoscaleAgent
  class Report

    attr_reader :measurements

    def initialize
      @measurements = []
    end

    def to_params(config)
      {
        dyno: config.dyno,
        pid: Process.pid,
      }
    end

    def to_csv
      String.new.tap do |result|
        @measurements.each do |measurement|
          result << [
            measurement.time.to_i,
            measurement.value,
            measurement.queue_name,
            measurement.metric,
          ].join(',')

          result << "\n"
        end
      end
    end

  end
end
