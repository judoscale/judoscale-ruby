# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/job_metrics_collector/active_record_helper"
require "judoscale/metric"

module Judoscale
  module Que
    class MetricsCollector < Judoscale::JobMetricsCollector
      include ActiveRecordHelper

      METRICS_SQL = ActiveRecordHelper.cleanse_sql(<<~SQL)
        SELECT queue, min(run_at)
        FROM que_jobs
        WHERE finished_at IS NULL
        AND expired_at IS NULL
        AND error_count = 0
        AND id NOT IN (
          SELECT (classid::bigint << 32) + objid::bigint AS id
          FROM pg_locks
          WHERE locktype = 'advisory'
        )
        GROUP BY 1
      SQL

      BUSY_METRICS_SQL = ActiveRecordHelper.cleanse_sql(<<~SQL)
        SELECT queue, count(*)
        FROM que_jobs
        WHERE id IN (
          SELECT (classid::bigint << 32) + objid::bigint AS id
          FROM pg_locks
          WHERE locktype = 'advisory'
        )
        GROUP BY 1
      SQL

      def self.adapter_config
        Judoscale::Config.instance.que
      end

      def self.collect?(config)
        super && ActiveRecordHelper.table_exists?("que_jobs")
      end

      def collect
        metrics = []
        time = Time.now.utc

        run_at_by_queue = select_rows_silently(METRICS_SQL).to_h
        self.queues |= run_at_by_queue.keys

        if track_busy_jobs?
          busy_count_by_queue = select_rows_silently(BUSY_METRICS_SQL).to_h
          self.queues |= busy_count_by_queue.keys
        end

        queues.each do |queue|
          run_at = run_at_by_queue[queue]
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
