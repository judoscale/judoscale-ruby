# frozen_string_literal: true

require 'rails_autoscale_agent/logger'
require 'time'

module RailsAutoscaleAgent
  module WorkerAdapters
    class Que
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
        defined? ::Que
      end

      def collect!(store)
        log_msg = String.new
        t = Time.now

        # Ignore failed jobs (they skew latency measurement due to the original run_at)
        sql = 'SELECT queue, min(run_at) FROM que_jobs WHERE error_count = 0 GROUP BY queue'
        run_at_by_queue = Hash[ActiveRecord::Base.connection.select_rows(sql)]
        self.class.queues |= run_at_by_queue.keys

        self.class.queues.each do |queue|
          run_at = run_at_by_queue[queue]
          run_at = Time.parse(run_at) if run_at.is_a?(String)
          latency_ms = run_at ? ((t - run_at)*1000).ceil : 0

          queue = UNNAMED_QUEUE if queue.nil? || queue.empty?
          store.push latency_ms, t, queue
          log_msg << "que.#{queue}=#{latency_ms} "
        end

        logger.debug log_msg unless log_msg.empty?
      end
    end
  end
end
