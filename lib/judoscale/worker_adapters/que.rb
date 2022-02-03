# frozen_string_literal: true

require "judoscale/worker_adapters/base"

module Judoscale
  module WorkerAdapters
    class Que < Base
      def enabled?
        if defined?(::Que)
          logger.info "Que enabled (#{::ActiveRecord::Base.default_timezone})"
          true
        end
      end

      def collect!(store)
        log_msg = +""
        t = Time.now.utc
        sql = <<~SQL
          SELECT queue, min(run_at)
          FROM que_jobs
          WHERE finished_at IS NULL
          AND expired_at IS NULL
          AND error_count = 0
          GROUP BY 1
        SQL

        run_at_by_queue = select_rows(sql).to_h

        return if number_of_queues_to_collect_exceeded_limit?(run_at_by_queue)

        self.queues |= run_at_by_queue.keys

        queues.each do |queue|
          run_at = run_at_by_queue[queue]
          run_at = DateTime.parse(run_at) if run_at.is_a?(String)
          latency_ms = run_at ? ((t - run_at) * 1000).ceil : 0
          latency_ms = 0 if latency_ms < 0

          store.push :qt, latency_ms, t, queue
          log_msg << "que-qt.#{queue}=#{latency_ms}ms "
        end

        logger.debug log_msg unless log_msg.empty?
      end

      private

      def select_rows(sql)
        # This ensures the agent doesn't hold onto a DB connection any longer than necessary
        ActiveRecord::Base.connection_pool.with_connection { |c| c.select_rows(sql) }
      end
    end
  end
end
