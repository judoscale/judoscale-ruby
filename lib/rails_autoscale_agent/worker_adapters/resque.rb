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
          size = ::Resque.size(queue)
          store.push size, Time.now, queue, :qd
          log_msg << "resque.#{queue}=#{size} "
        end

        logger.debug log_msg
      end
    end
  end
end
