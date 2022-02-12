# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  module WorkerAdapters
    class DelayedJob
      include RailsAutoscaleAgent::Logger
      include Singleton

      attr_writer :queues

      def enabled?
        if defined?(::Delayed::Job) && defined?(::Delayed::Backend::ActiveRecord)
          log_msg = String.new("DelayedJob enabled (#{default_timezone})")
          log_msg << " with long-running job support" if track_long_running_jobs?
          logger.info log_msg
          true
        end
      end

      def collect!(store)
        log_msg = String.new
        t = Time.now.utc
        sql = <<~SQL
          SELECT COALESCE(queue, 'default'), min(run_at)
          FROM delayed_jobs
          WHERE locked_at IS NULL
          AND failed_at IS NULL
          GROUP BY queue
        SQL

        run_at_by_queue = Hash[select_rows_silently(sql)]

        # Don't collect worker metrics if there are unreasonable number of queues
        if run_at_by_queue.size > Config.instance.max_queues
          logger.warn "Skipping DelayedJob metrics - #{run_at_by_queue.size} queues exceeds the #{Config.instance.max_queues} queue limit"
          return
        end

        self.queues = queues | run_at_by_queue.keys

        if track_long_running_jobs?
          sql = <<~SQL
            SELECT COALESCE(queue, 'default'), count(*)
            FROM delayed_jobs
            WHERE locked_at IS NOT NULL
            AND locked_by IS NOT NULL
            AND failed_at IS NULL
            GROUP BY 1
          SQL

          busy_count_by_queue = Hash[select_rows_silently(sql)]
          self.queues = queues | busy_count_by_queue.keys
        end

        queues.each do |queue|
          run_at = run_at_by_queue[queue]
          # DateTime.parse assumes a UTC string
          run_at = DateTime.parse(run_at) if run_at.is_a?(String)
          latency_ms = run_at ? ((t - run_at)*1000).ceil : 0
          latency_ms = 0 if latency_ms < 0

          store.push latency_ms, t, queue
          log_msg << "dj-qt.#{queue}=#{latency_ms} "

          if track_long_running_jobs?
            busy_count = busy_count_by_queue[queue] || 0
            store.push busy_count, Time.now, queue, :busy
            log_msg << "dj-busy.#{queue}=#{busy_count} "
          end
        end

        logger.debug log_msg unless log_msg.empty?
      end

      private

      def queues
        # Track the known queues so we can continue reporting on queues that don't
        # have enqueued jobs at the time of reporting.
        # Assume a "default" queue so we always report *something*, even when nothing
        # is enqueued.
        @queues ||= Set.new(['default'])
      end

      def track_long_running_jobs?
        Config.instance.track_long_running_jobs
      end

      def default_timezone
        if ::ActiveRecord.respond_to?(:default_timezone)
          # Rails >= 7
          ::ActiveRecord.default_timezone
        else
          # Rails < 7
          ::ActiveRecord::Base.default_timezone
        end
      end

      def select_rows_silently(sql)
        if ::ActiveRecord::Base.logger.respond_to?(:silence)
          ::ActiveRecord::Base.logger.silence { select_rows(sql) }
        else
          select_rows(sql)
        end
      end

      def select_rows(sql)
        # This ensures the agent doesn't hold onto a DB connection any longer than necessary
        ActiveRecord::Base.connection_pool.with_connection { |c| c.select_rows(sql) }
      end
    end
  end
end
