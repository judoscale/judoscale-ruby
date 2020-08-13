# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  module WorkerAdapters
    class Sidekiq
      include RailsAutoscaleAgent::Logger
      include Singleton

      attr_writer :known_queue_names

      def known_queue_names
        @known_queue_names ||= ['default']
      end

      def enabled?
        require 'sidekiq/api'
        logger.info "Sidekiq enabled"
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
        if queues_by_name.size > 50
          logger.debug "Skipping Sidekiq metrics - #{queues_by_name.size} queues"
          return
        end

        # Ensure we continue to collect metrics for known queue names, even when nothing is
        # enqueued at the time. Without this, it will appear that the agent is no longer reporting.
        known_queue_names.each do |queue_name|
          queues_by_name[queue_name] ||= ::Sidekiq::Queue.new(queue_name)
        end
        self.known_queue_names = queues_by_name.keys

        queues_by_name.each do |queue_name, queue|
          latency_ms = (queue.latency * 1000).ceil
          depth = queue.size
          store.push latency_ms, Time.now, queue.name, :qt
          store.push depth, Time.now, queue.name, :qd
          log_msg << "sidekiq-qt.#{queue.name}=#{latency_ms} sidekiq-qd.#{queue.name}=#{depth} "
        end

        logger.debug log_msg
      end
    end
  end
end
