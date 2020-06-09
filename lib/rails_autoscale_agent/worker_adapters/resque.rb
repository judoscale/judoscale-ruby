# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  module WorkerAdapters
    class Resque
      include RailsAutoscaleAgent::Logger
      include Singleton

      def enabled?
        require 'resque'
        true
      rescue LoadError
        false
      end

      def collect!(store)
        log_msg = String.new

        ::Resque.queues.each do |queue|
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
