# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/job_metrics_collector/active_record_helper"
require "judoscale/metric"

module Judoscale
  module DelayedJob
    class MetricsCollector < Judoscale::JobMetricsCollector
      include ActiveRecordHelper

      METRICS_SQL = ActiveRecordHelper.cleanse_sql(<<~SQL)
        SELECT COALESCE(queue, 'default'), min(run_at)
        FROM delayed_jobs
        WHERE locked_at IS NULL
        AND failed_at IS NULL
        GROUP BY queue
      SQL

      # Returns the oldest unlocked job and the count of locked (busy) jobs per queue in a single pass,
      # since `delayed_jobs` has no index for either filter and each separate query scans the whole table.
      METRICS_WITH_BUSY_SQL = ActiveRecordHelper.cleanse_sql(<<~SQL)
        SELECT COALESCE(queue, 'default'),
          min(CASE WHEN locked_at IS NULL THEN run_at END),
          sum(CASE WHEN locked_at IS NOT NULL THEN 1 ELSE 0 END)
        FROM delayed_jobs
        WHERE failed_at IS NULL
        AND (locked_at IS NULL OR locked_by IS NOT NULL)
        GROUP BY 1
      SQL

      def self.adapter_config
        Judoscale::Config.instance.delayed_job
      end

      def self.collect?(config)
        super && ActiveRecordHelper.table_exists?("delayed_jobs")
      end

      def collect
        metrics = []
        time = Time.now.utc

        if track_busy_jobs?
          rows = select_rows_silently(METRICS_WITH_BUSY_SQL)
          run_at_by_queue = rows.each_with_object({}) { |(queue, run_at, _), h| h[queue] = run_at if run_at }
          busy_count_by_queue = rows.each_with_object({}) { |(queue, _, busy_count), h| h[queue] = busy_count.to_i if busy_count.to_i > 0 }
        else
          run_at_by_queue = select_rows_silently(METRICS_SQL).to_h
        end
        self.queues |= run_at_by_queue.keys
        self.queues |= busy_count_by_queue.keys if track_busy_jobs?

        queues.each do |queue|
          run_at = run_at_by_queue[queue]
          # DateTime.parse assumes a UTC string
          run_at = DateTime.parse(run_at) if run_at.is_a?(String)
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
