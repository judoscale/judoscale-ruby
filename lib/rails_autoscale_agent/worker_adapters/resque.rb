# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  module WorkerAdapters
    class Resque
      include RailsAutoscaleAgent::Logger
      include Singleton

      attr_writer :queues

      def queues
        @queues ||= ['default']
      end

      def enabled?
        require 'resque'
        logger.info "Resque enabled"
        true
      rescue LoadError
        false
      end

      def collect!(store)
        log_msg = String.new
        current_queues = ::Resque.queues

        # Don't collect worker metrics if there are unreasonable number of queues
        if current_queues.size > Config.instance.max_queues
          logger.warn "Skipping Resque metrics - #{current_queues.size} queues exceeds the #{Config.instance.max_queues} queue limit"
          return
        end

        # Ensure we continue to collect metrics for known queue names, even when nothing is
        # enqueued at the time. Without this, it will appears that the agent is no longer reporting.
        self.queues |= current_queues

        queues.each do |queue|
          next if queue.nil? || queue.empty?
          depth = ::Resque.size(queue)
          store.push depth, Time.now, queue, :qd
          log_msg << "resque-qd.#{queue}=#{depth} "
        end

        logger.debug log_msg
      end
    end
  end
end
