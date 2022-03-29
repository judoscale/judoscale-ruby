# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/metric"

module Judoscale
  module Resque
    class MetricsCollector < Judoscale::JobMetricsCollector
      def self.adapter_identifier
        :resque
      end

      def collect
        store = []
        log_msg = +""
        current_queues = ::Resque.queues
        # Ensure we continue to collect metrics for known queue names, even when nothing is
        # enqueued at the time. Without this, it will appears that the agent is no longer reporting.
        self.queues |= current_queues

        queues.each do |queue|
          next if queue.nil? || queue.empty?
          depth = ::Resque.size(queue)
          store.push Metric.new(:qd, depth, Time.now, queue)
          log_msg << "resque-qd.#{queue}=#{depth} "
        end

        logger.debug log_msg
        store
      end
    end
  end
end
