# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  module WorkerAdapters
    class Sidekiq
      include RailsAutoscaleAgent::Logger
      include Singleton

      def enabled?
        require 'sidekiq/api'
        logger.info "Sidekiq enabled"
        true
      rescue LoadError
        false
      end

      def collect!(store)
        log_msg = String.new

        ::Sidekiq::Queue.all.each do |queue|
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
