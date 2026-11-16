# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/metric"

module Judoscale
  module Resque
    class MetricsCollector < Judoscale::JobMetricsCollector
      def self.adapter_config
        Judoscale::Config.instance.resque
      end

      def collect
        metrics = []
        time = Time.now.utc
        current_queues = ::Resque.queues

        if track_busy_jobs?
          busy_counts = Hash.new { |h, k| h[k] = 0 }

          # `Resque.working` reads every worker's job in one call and skips idle workers. `job(false)` uses
          # that job instead of fetching it again, which would cost a Redis round trip per busy worker.
          ::Resque.working.each do |worker|
            busy_counts[worker.job(false)["queue"]] += 1
          end
        end

        self.queues |= current_queues

        queues.each do |queue|
          next if queue.nil? || queue.empty?
          depth = ::Resque.size(queue)
          latency = (::Resque.latency(queue) * 1000).ceil

          metrics.push Metric.new(:qd, depth, time, queue)
          metrics.push Metric.new(:qt, latency, time, queue)

          if track_busy_jobs?
            busy_count = busy_counts[queue]
            metrics.push Metric.new(:busy, busy_count, time, queue)
          end
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
