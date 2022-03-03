# frozen_string_literal: true

require "judoscale/metrics_collector"
require "judoscale/logger"

module Judoscale
  class JobMetricsCollector < MetricsCollector
    include Judoscale::Logger

    # It's redundant to report these metrics from every dyno, so only report from the first one.
    def self.collect?(config)
      config.dyno_num == 1
    end
  end
end
