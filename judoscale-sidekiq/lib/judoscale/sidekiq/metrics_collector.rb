# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/metric"

module Judoscale
  module Sidekiq
    class MetricsCollector < Judoscale::JobMetricsCollector
      RECENT = 1 # second
      RECENT_KEY = "judoscale:sidekiq:recent"
      RECENT_VALUE = "1"

      def self.adapter_config
        Judoscale::Config.instance.sidekiq
      end

      def collect
        return [] if collected_recently?

        metrics = []
        queues_by_name = ::Sidekiq::Queue.all.each_with_object({}) do |queue, obj|
          obj[queue.name] = queue
        end

        self.queues |= queues_by_name.keys

        if track_busy_jobs?
          busy_counts = Hash.new { |h, k| h[k] = 0 }
          ::Sidekiq::Workers.new.each do |pid, tid, work|
            # Sidekiq 7.2 added a new Sidekiq::Work type; hash access is deprecated
            payload = work.payload if work.respond_to?(:payload)
            payload ||= work["payload"]
            # payload is unparsed in Sidekiq 7
            payload = JSON.parse(payload) if payload.is_a?(String)
            busy_counts[payload["queue"]] += 1
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

      def forget_recent_collection!
        # We need this for testing
        ::Sidekiq.redis { |r| r.del RECENT_KEY }
      end

      private

      def collected_recently?
        # If another process has collected metrics recently, we don't need to.
        !::Sidekiq.redis { |r| r.set RECENT_KEY, RECENT_VALUE, nx: true, ex: RECENT }
      end
    end
  end
end
