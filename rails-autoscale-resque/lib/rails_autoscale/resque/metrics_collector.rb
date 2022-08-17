# frozen_string_literal: true

require "rails_autoscale/job_metrics_collector"
require "rails_autoscale/metric"

module RailsAutoscale
  module Resque
    class MetricsCollector < RailsAutoscale::JobMetricsCollector
      def self.adapter_config
        RailsAutoscale::Config.instance.resque
      end

      def collect
        metrics = []
        current_queues = ::Resque.queues

        if track_busy_jobs?
          busy_counts = Hash.new { |h, k| h[k] = 0 }

          ::Resque.working.each do |worker|
            if !worker.idle? && (job = worker.job)
              busy_counts[job["queue"]] += 1
            end
          end
        end

        self.queues |= current_queues

        queues.each do |queue|
          next if queue.nil? || queue.empty?
          depth = ::Resque.size(queue)
          latency = (::Resque.latency(queue) * 1000).ceil

          metrics.push Metric.new(:qd, depth, Time.now, queue)
          metrics.push Metric.new(:qt, latency, Time.now, queue)

          if track_busy_jobs?
            busy_count = busy_counts[queue]
            metrics.push Metric.new(:busy, busy_count, Time.now, queue)
          end
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
