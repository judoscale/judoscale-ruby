module RailsAutoscaleAgent
  class Report

    attr_reader :measurements

    def initialize
      @measurements = []
    end

    def to_params(config)
      {
        dyno: config.dyno,
        pid: config.pid,
      }
    end

    def to_csv
      ''.tap do |result|
        @measurements.each do |measurement|
          result << measurement.time.to_i.to_s
          result << ','.freeze
          result << measurement.value.to_s
          result << "\n".freeze
        end
      end
    end

  end
end
