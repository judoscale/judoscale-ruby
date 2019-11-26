# frozen_string_literal: true

require 'rails_autoscale_agent/logger'

module WorkerAdapters
  class Sidekiq
    include RailsAutoscaleAgent::Logger

    def enabled?
      require 'sidekiq/api'
      true
    rescue LoadError
      false
    end

    def collect!(store)
      log_msg = String.new('Sidekiq latency ')

      ::Sidekiq::Queue.all.each do |queue|
        latency_ms = (queue.latency * 1000).ceil
        store.push latency_ms, Time.now, queue.name
        log_msg << "#{queue.name}=#{latency_ms} "
      end

      logger.debug log_msg
    end
  end
end
