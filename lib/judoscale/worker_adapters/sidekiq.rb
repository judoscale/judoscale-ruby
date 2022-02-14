# frozen_string_literal: true

require "judoscale/worker_adapters/base"

module Judoscale
  module WorkerAdapters
    class Sidekiq < Base
      def enabled?
        require "sidekiq/api"

        log_msg = +"Sidekiq enabled"
        log_msg << " with busy job tracking support" if track_busy_jobs?
        logger.info log_msg

        true
      rescue LoadError
        false
      end

      def collect!(store)
        log_msg = +""
        queues_by_name = ::Sidekiq::Queue.all.each_with_object({}) do |queue, obj|
          obj[queue.name] = queue
        end

        self.queues |= queues_by_name.keys

        if track_busy_jobs?
          busy_counts = Hash.new { |h, k| h[k] = 0 }
          ::Sidekiq::Workers.new.each do |pid, tid, work|
            busy_counts[work.dig("payload", "queue")] += 1
          end
        end

        queues.each do |queue_name|
          queue = queues_by_name.fetch(queue_name) { |name| ::Sidekiq::Queue.new(name) }
          latency_ms = (queue.latency * 1000).ceil
          depth = queue.size

          store.push :qt, latency_ms, Time.now, queue_name
          store.push :qd, depth, Time.now, queue_name
          log_msg << "sidekiq-qt.#{queue_name}=#{latency_ms}ms sidekiq-qd.#{queue_name}=#{depth} "

          if track_busy_jobs?
            busy_count = busy_counts[queue_name]
            store.push :busy, busy_count, Time.now, queue_name
            log_msg << "sidekiq-busy.#{queue_name}=#{busy_count} "
          end
        end

        logger.debug log_msg
      end
    end
  end
end
