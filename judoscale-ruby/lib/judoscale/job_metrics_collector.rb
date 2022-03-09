# frozen_string_literal: true

require "judoscale/metrics_collector"

module Judoscale
  class JobMetricsCollector < MetricsCollector
    # It's redundant to report these metrics from every dyno, so only report from the first one.
    def self.collect?(config)
      config.dyno_num == 1
    end
  end
end
