# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module WorkerAdapters
  class DelayedJob
    include RailsAutoscaleAgent::Logger

    def initialize
      @queues = []
    end

    def enabled?
      defined? ::Delayed
    end

    def collect!(store)
      log_msg = String.new('DelayedJob latency ')
      t = Time.now

      sql = 'SELECT queue, min(run_at) FROM delayed_jobs GROUP BY queue'
      run_at_by_queue = Hash[ActiveRecord::Base.connection.select_rows(sql)]

      # Track the known queues so we can continue reporting on queues that don't
      # currently have enqueued jobs.
      @queues |= run_at_by_queue.keys

      @queues.each do |queue|
        run_at = run_at_by_queue[queue]
        latency_ms = run_at ? ((t - run_at)*1000).ceil : 0
        store.push latency_ms, t, queue
        log_msg << "#{queue}=#{latency_ms} "
      end

      logger.debug log_msg
    end
  end
end
