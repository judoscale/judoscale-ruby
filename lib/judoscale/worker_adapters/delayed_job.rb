# frozen_string_literal: true

require "judoscale/worker_adapters/base"
require "judoscale/worker_adapters/active_record_helper"

module Judoscale
  module WorkerAdapters
    class DelayedJob < Base
      include ActiveRecordHelper

      def enabled?
        if defined?(::Delayed::Job) && defined?(::Delayed::Backend::ActiveRecord)
          log_msg = +"DelayedJob enabled (#{::ActiveRecord::Base.default_timezone})"
          log_msg << " with long-running job support" if track_long_running_jobs?
          logger.info log_msg
          true
        end
      end

      def collect!(store)
        log_msg = +""
        t = Time.now.utc
        sql = <<~SQL
          SELECT COALESCE(queue, 'default'), min(run_at)
          FROM delayed_jobs
          WHERE locked_at IS NULL
          AND failed_at IS NULL
          GROUP BY queue
        SQL

        run_at_by_queue = select_rows_silently(sql).to_h
        self.queues |= run_at_by_queue.keys

        if track_long_running_jobs?
          sql = <<~SQL
            SELECT COALESCE(queue, 'default'), count(*)
            FROM delayed_jobs
            WHERE locked_at IS NOT NULL
            AND locked_by IS NOT NULL
            AND failed_at IS NULL
            GROUP BY 1
          SQL

          busy_count_by_queue = select_rows_silently(sql).to_h
          self.queues |= busy_count_by_queue.keys
        end

        queues.each do |queue|
          run_at = run_at_by_queue[queue]
          # DateTime.parse assumes a UTC string
          run_at = DateTime.parse(run_at) if run_at.is_a?(String)
          latency_ms = run_at ? ((t - run_at) * 1000).ceil : 0
          latency_ms = 0 if latency_ms < 0

          store.push :qt, latency_ms, t, queue
          log_msg << "dj-qt.#{queue}=#{latency_ms}ms "

          if track_long_running_jobs?
            busy_count = busy_count_by_queue[queue] || 0
            store.push :busy, busy_count, Time.now, queue
            log_msg << "dj-busy.#{queue}=#{busy_count} "
          end
        end

        logger.debug log_msg unless log_msg.empty?
      end
    end
  end
end
