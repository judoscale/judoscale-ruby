# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/metric"

module Judoscale
  module Sidekiq
    class MetricsCollector < Judoscale::JobMetricsCollector
      def self.adapter_config
        Judoscale::Config.instance.sidekiq
      end

      def collect
        metrics = []
        time = Time.now.utc
        queues_by_name = ::Sidekiq::Queue.all.each_with_object({}) do |queue, obj|
          obj[queue.name] = queue
        end

        self.queues |= queues_by_name.keys

        if track_busy_jobs?
          busy_counts = Hash.new { |h, k| h[k] = 0 }
          oldest_run_at_by_queue = {}
          ::Sidekiq::Workers.new.each do |pid, tid, work|
            # Sidekiq 7.2 added a new Sidekiq::Work type; hash access is deprecated
            if work.respond_to?(:payload)
              payload = work.payload
              run_at = work.run_at
            else
              payload = work["payload"]
              run_at = Time.at(work["run_at"])
            end
            # payload is unparsed in Sidekiq 7
            payload = JSON.parse(payload) if payload.is_a?(String)
            queue_name = payload["queue"]
            busy_counts[queue_name] += 1
            oldest_run_at = oldest_run_at_by_queue[queue_name]
            oldest_run_at_by_queue[queue_name] = run_at if oldest_run_at.nil? || run_at < oldest_run_at
          end
        end

        queues.each do |queue_name|
          queue = queues_by_name.fetch(queue_name) { |name| ::Sidekiq::Queue.new(name) }
          latency_ms = (queue.latency * 1000).ceil
          depth = queue.size

          metrics.push Metric.new(:qt, latency_ms, time, queue_name)
          metrics.push Metric.new(:qd, depth, time, queue_name)

          if track_busy_jobs?
            busy_count = busy_counts[queue_name]
            metrics.push Metric.new(:busy, busy_count, time, queue_name)

            run_at = oldest_run_at_by_queue[queue_name]
            busy_time_ms = run_at ? ((time - run_at) * 1000).ceil : 0
            busy_time_ms = 0 if busy_time_ms < 0
            metrics.push Metric.new(:bt, busy_time_ms, time, queue_name)
          end
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
