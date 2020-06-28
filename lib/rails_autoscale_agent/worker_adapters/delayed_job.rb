# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  module WorkerAdapters
    class DelayedJob
      include RailsAutoscaleAgent::Logger
      include Singleton

      class << self
        attr_writer :queues
      end

      def self.queues
        # Track the known queues so we can continue reporting on queues that don't
        # have enqueued jobs at the time of reporting.
        # Assume a "default" queue so we always report *something*, even when nothing
        # is enqueued.
        @queues ||= Set.new(['default'])
      end

      def enabled?
        if defined?(::Delayed::Job) && defined?(::Delayed::Backend::ActiveRecord)
          logger.info "DelayedJob enabled (#{::ActiveRecord::Base.default_timezone})"
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

        run_at_by_queue = Hash[ActiveRecord::Base.connection.select_rows(sql)]
        self.class.queues |= run_at_by_queue.keys

        self.class.queues.each do |queue|
          run_at = run_at_by_queue[queue]
          # DateTime.parse assumes a UTC string
          run_at = DateTime.parse(run_at) if run_at.is_a?(String)
          latency_ms = run_at ? ((t - run_at)*1000).ceil : 0
          latency_ms = 0 if latency_ms < 0

          store.push latency_ms, t, queue
          log_msg << "dj.#{queue}=#{latency_ms} "
        end

        logger.debug log_msg unless log_msg.empty?
      end
    end
  end
end
