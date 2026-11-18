# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/job_metrics_collector/active_record_helper"
require "judoscale/metric"

module Judoscale
  module DelayedJob
    class MetricsCollector < Judoscale::JobMetricsCollector
      include ActiveRecordHelper

      # Returns the oldest unlocked job, the count of locked (busy) jobs, and the oldest lock per queue in a single
      # pass, since `delayed_jobs` has no index for any filter and each separate query scans the whole table.
      # Locks older than the max run time were left by a worker that died, so they don't count as busy.
      METRICS_SQL = ActiveRecordHelper.cleanse_sql(<<~SQL)
        SELECT COALESCE(queue, 'default'),
          min(CASE WHEN locked_at IS NULL THEN run_at END),
          sum(CASE WHEN locked_at > :stale_lock_time THEN 1 ELSE 0 END),
          min(CASE WHEN locked_at > :stale_lock_time THEN locked_at END)
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

        stale_lock_time = time - ::Delayed::Worker.max_run_time
        rows = select_rows_silently(::ActiveRecord::Base.sanitize_sql_array([METRICS_SQL, stale_lock_time: stale_lock_time]))
        run_at_by_queue = rows.to_h { |queue, run_at, _, _| [queue, run_at] }
        busy_count_by_queue = rows.to_h { |queue, _, busy_count, _| [queue, busy_count.to_i] }
        locked_at_by_queue = rows.to_h { |queue, _, _, locked_at| [queue, locked_at] }
        self.queues |= rows.map(&:first)

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

            locked_at = locked_at_by_queue[queue]
            locked_at = DateTime.parse(locked_at) if locked_at.is_a?(String)
            busy_time_ms = locked_at ? ((time - locked_at) * 1000).ceil : 0
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
