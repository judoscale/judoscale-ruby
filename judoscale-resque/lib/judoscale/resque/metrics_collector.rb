# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/metric"
require "time"

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
          oldest_run_at_by_queue = {}

          # `Resque.working` reads every worker's job in one call and skips idle workers. `job(false)` uses
          # that job instead of fetching it again, which would cost a Redis round trip per busy worker.
          ::Resque.working.each do |worker|
            job = worker.job(false)
            queue = job["queue"]
            run_at = Time.iso8601(job["run_at"])
            busy_counts[queue] += 1
            oldest_run_at = oldest_run_at_by_queue[queue]
            oldest_run_at_by_queue[queue] = run_at if oldest_run_at.nil? || run_at < oldest_run_at
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

            run_at = oldest_run_at_by_queue[queue]
            busy_time_ms = run_at ? ((time - run_at) * 1000).ceil : 0
            busy_time_ms = 0 if busy_time_ms < 0
            metrics.push Metric.new(:bt, busy_time_ms, time, queue)
          end
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
