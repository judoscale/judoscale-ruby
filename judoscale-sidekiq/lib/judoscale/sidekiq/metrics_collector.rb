# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/metric"

module Judoscale
  module Sidekiq
    class MetricsCollector < Judoscale::JobMetricsCollector
      def self.adapter_identifier
        :sidekiq
      end

      def collect
        store = []
        log_msg = +""
        queues_by_name = ::Sidekiq::Queue.all.each_with_object({}) do |queue, obj|
          obj[queue.name] = queue
        end

        self.queues |= queues_by_name.keys

        if track_busy_jobs?
          busy_counts = Hash.new { |h, k| h[k] = 0 }
          ::Sidekiq::Workers.new.each do |pid, tid, work|
            busy_counts[work.dig("payload", "queue")] += 1
          end
        end

        queues.each do |queue_name|
          queue = queues_by_name.fetch(queue_name) { |name| ::Sidekiq::Queue.new(name) }
          latency_ms = (queue.latency * 1000).ceil
          depth = queue.size

          store.push Metric.new(:qt, latency_ms, Time.now, queue_name)
          store.push Metric.new(:qd, depth, Time.now, queue_name)
          log_msg << "sidekiq-qt.#{queue_name}=#{latency_ms}ms sidekiq-qd.#{queue_name}=#{depth} "

          if track_busy_jobs?
            busy_count = busy_counts[queue_name]
            store.push Metric.new(:busy, busy_count, Time.now, queue_name)
            log_msg << "sidekiq-busy.#{queue_name}=#{busy_count} "
          end
        end

        logger.debug log_msg
        store
      end
    end
  end
end
