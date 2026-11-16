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

          worker_payloads.each do |payload|
            next if payload.nil? || payload.empty?
            busy_counts[::Resque.decode(payload)["queue"]] += 1
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

      private

      # Fetches every worker's current job payload (nil or empty when idle) in a single round trip.
      # `Resque.working` fetches these too but discards them, so reading each worker's job afterwards
      # costs two more round trips per busy worker.
      def worker_payloads
        data_store = ::Resque.data_store
        worker_ids = data_store.worker_ids
        return [] if worker_ids.empty?

        data_store.workers_map(worker_ids).values
      rescue => e
        # Same fallback as `Resque.working`: distributed Redis can't MGET keys across nodes.
        # `Redis::Distributed` is only loaded when the app uses it, so don't reference it unconditionally.
        raise unless defined?(::Redis::Distributed::CannotDistribute) && e.is_a?(::Redis::Distributed::CannotDistribute)

        worker_ids.map { |worker_id| data_store.get_worker_payload(worker_id) }
      end
    end
  end
end
