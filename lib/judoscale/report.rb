# frozen_string_literal: true

module Judoscale
  class Report
    attr_reader :metrics

    def initialize
      @metrics = []
    end

    def to_params(config)
      {
        dyno: config.dyno,
        pid: Process.pid
      }
    end

    def to_csv
      (+"").tap do |result|
        @metrics.each do |metric|
          result << [
            metric.time.to_i,
            metric.value,
            metric.queue_name,
            metric.identifier
          ].join(",")

          result << "\n"
        end
      end
    end
  end
end
