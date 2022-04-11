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

      def self.adapter_identifier
        :que
      end

      def collect
        store = []
        log_msg = +""
        t = Time.now.utc

        run_at_by_queue = select_rows_silently(METRICS_SQL).to_h
        self.queues |= run_at_by_queue.keys

        queues.each do |queue|
          run_at = run_at_by_queue[queue]
          run_at = DateTime.parse(run_at) if run_at.is_a?(String)
          latency_ms = run_at ? ((t - run_at) * 1000).ceil : 0
          latency_ms = 0 if latency_ms < 0

          store.push Metric.new(:qt, latency_ms, t, queue)
          log_msg << "que-qt.#{queue}=#{latency_ms}ms "
        end

        logger.debug log_msg unless log_msg.empty?
        store
      end
    end
  end
end
