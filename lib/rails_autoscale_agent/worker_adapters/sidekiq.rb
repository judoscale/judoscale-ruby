# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  module WorkerAdapters
    class Sidekiq
      include RailsAutoscaleAgent::Logger
      include Singleton

      attr_writer :queues

      def enabled?
        require 'sidekiq/api'

        log_msg = String.new("Sidekiq enabled")
        log_msg << " with long-running job support" if track_long_running_jobs?
        logger.info log_msg

        true
      rescue LoadError
        false
      end

      def collect!(store)
        log_msg = String.new
        queues_by_name = ::Sidekiq::Queue.all.each_with_object({}) do |queue, obj|
          obj[queue.name] = queue
        end

        # Don't collect worker metrics if there are unreasonable number of queues
        if queues_by_name.size > Config.instance.max_queues
          logger.warn "Skipping Sidekiq metrics - #{queues_by_name.size} queues exceeds the #{Config.instance.max_queues} queue limit"
          return
        end

        # Ensure we continue to collect metrics for known queue names, even when nothing is
        # enqueued at the time. Without this, it will appear that the agent is no longer reporting.
        queues.each do |queue_name|
          queues_by_name[queue_name] ||= ::Sidekiq::Queue.new(queue_name)
        end
        self.queues = queues_by_name.keys

        if track_long_running_jobs?
          busy_counts = Hash.new { |h,k| h[k] = 0}
          ::Sidekiq::Workers.new.each do |pid, tid, work|
            busy_counts[work.dig('payload', 'queue')] += 1
          end
        end

        queues_by_name.each do |queue_name, queue|
          latency_ms = (queue.latency * 1000).ceil
          depth = queue.size

          store.push latency_ms, Time.now, queue.name, :qt
          store.push depth, Time.now, queue.name, :qd
          log_msg << "sidekiq-qt.#{queue.name}=#{latency_ms} sidekiq-qd.#{queue.name}=#{depth} "

          if track_long_running_jobs?
            busy_count = busy_counts[queue.name]
            store.push busy_count, Time.now, queue.name, :busy
            log_msg << "sidekiq-busy.#{queue.name}=#{busy_count} "
          end
        end

        logger.debug log_msg
      end

      private

      def queues
        @queues ||= ['default']
      end

      def track_long_running_jobs?
        Config.instance.track_long_running_jobs
      end
    end
  end
end
