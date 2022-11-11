# frozen_string_literal: true

require "rails_autoscale/job_metrics_collector"
require "rails_autoscale/metric"

module RailsAutoscale
  module Sidekiq
    class MetricsCollector < RailsAutoscale::JobMetricsCollector
      def self.adapter_config
        RailsAutoscale::Config.instance.sidekiq
      end

      def collect
        metrics = []
        queues_by_name = ::Sidekiq::Queue.all.each_with_object({}) do |queue, obj|
          obj[queue.name] = queue
        end

        self.queues |= queues_by_name.keys

        if track_busy_jobs?
          busy_counts = Hash.new { |h, k| h[k] = 0 }
          ::Sidekiq::Workers.new.each do |pid, tid, work|
            busy_counts[work.dig("payload", "queue")] += 1
          rescue TypeError
            # We've seen scenarios from customers where the payload is a String instead of Hash.
            # We're not sure why, but we need to gracefully handle it.
          end
        end

        queues.each do |queue_name|
          queue = queues_by_name.fetch(queue_name) { |name| ::Sidekiq::Queue.new(name) }
          latency_ms = (queue.latency * 1000).ceil
          depth = queue.size

          metrics.push Metric.new(:qt, latency_ms, Time.now, queue_name)
          metrics.push Metric.new(:qd, depth, Time.now, queue_name)

          if track_busy_jobs?
            busy_count = busy_counts[queue_name]
            metrics.push Metric.new(:busy, busy_count, Time.now, queue_name)
          end
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
