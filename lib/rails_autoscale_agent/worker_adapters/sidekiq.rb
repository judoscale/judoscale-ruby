# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module WorkerAdapters
  class Sidekiq
    include RailsAutoscaleAgent::Logger
    include Singleton

    def enabled?
      require 'sidekiq/api'
      true
    rescue LoadError
      false
    end

    def collect!(store)
      log_msg = String.new('Sidekiq latency ')
      workers_by_queue = ::Sidekiq::Workers.new.group_by do |process_id, thread_id, work|
        work.dig 'payload', 'queue'
      end

      ::Sidekiq::Queue.all.each do |queue|
        workers = Array(workers_by_queue[queue.name])
        latency_ms = (queue.latency * 1000).ceil

        # If there are active running jobs on this queue, ensure the latency is
        # reported as at least 200ms. This is a hack to avoid downscaling and
        # killing long-running jobs.
        latency_ms = 200 if latency_ms < 200 && workers.any?

        store.push latency_ms, Time.now, queue.name
        log_msg << "#{queue.name}=#{latency_ms} "
      end

      logger.debug log_msg
    end
  end
end
