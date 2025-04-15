# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/job_metrics_collector/active_record_helper"
require "judoscale/metric"

module Judoscale
  module SolidQueue
    class MetricsCollector < Judoscale::JobMetricsCollector
      include ActiveRecordHelper

      def self.adapter_config
        Judoscale::Config.instance.solid_queue
      end

      def self.collect?(config)
        super && ActiveRecordHelper.table_exists_for_model?(::SolidQueue::Job)
      end

      def initialize
        super

        queue_names = run_silently do
          ::SolidQueue::Job.distinct.pluck(:queue_name)
        end
        self.queues |= queue_names
      end

      def collect
        metrics = []
        time = Time.now.utc

        oldest_execution_time_by_queue = run_silently do
          ::SolidQueue::ReadyExecution.group(:queue_name).minimum(:created_at)
        end
        self.queues |= oldest_execution_time_by_queue.keys

        if track_busy_jobs?
          busy_count_by_queue = run_silently do
            ::SolidQueue::Job.joins(:claimed_execution).group(:queue_name).count
          end
          self.queues |= busy_count_by_queue.keys
        end

        queues.each do |queue|
          run_at = oldest_execution_time_by_queue[queue]
          latency_ms = run_at ? ((time - run_at) * 1000).ceil : 0
          latency_ms = 0 if latency_ms < 0

          metrics.push Metric.new(:qt, latency_ms, time, queue)

          if track_busy_jobs?
            busy_count = busy_count_by_queue[queue] || 0
            metrics.push Metric.new(:busy, busy_count, time, queue)
          end
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
