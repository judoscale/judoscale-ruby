# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  module WorkerAdapters
    class DelayedJob
      include RailsAutoscaleAgent::Logger
      include Singleton

      UNNAMED_QUEUE = '[unnamed]'

      class << self
        attr_accessor :queues
      end

      def initialize
        # Track the known queues so we can continue reporting on queues that don't
        # currently have enqueued jobs.
        self.class.queues = Set.new
      end

      def enabled?
        if defined?(::Delayed::Job) && defined?(::Delayed::Backend::ActiveRecord)
          logger.info "Initializing DelayedJob reporting for Rails Autoscale (#{::ActiveRecord::Base.default_timezone})"
          true
        end
      end

      def collect!(store)
        log_msg = String.new
        t = Time.now.utc
        sql = <<~SQL
          SELECT queue, min(run_at)
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

          queue = UNNAMED_QUEUE if queue.nil? || queue.empty?
          store.push latency_ms, t, queue
          log_msg << "dj.#{queue}=#{latency_ms} "
        end

        logger.debug log_msg unless log_msg.empty?
      end
    end
  end
end
