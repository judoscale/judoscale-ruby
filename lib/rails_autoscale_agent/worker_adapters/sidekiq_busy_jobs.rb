# frozen_string_literal: true

require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  module WorkerAdapters
    class SidekiqBusyJobs
      include RailsAutoscaleAgent::Logger
      include Singleton

      def enabled?
        return false unless Config.instance.track_long_running_jobs
        require 'sidekiq/api'
        logger.info "SidekiqBusyJobs enabled"
        true
      rescue LoadError
        false
      end

      def collect!(store)
        log_msg = String.new
        busy_counts = Hash.new { |h,k| h[k] = 0}

        ::Sidekiq::Workers.new.each do |pid, tid, work|
          busy_counts[work.dig('payload', 'queue')] += 1
        end

        # Ensure we capture a busy metric for each queue, even if it's not busy rigth now.
        ::Sidekiq::Queue.all.each do |queue|
          busy_count = busy_counts[queue.name]
          store.push busy_count, Time.now, queue.name, :busy
          log_msg << "sidekiq-busy-jobs.#{queue.name}=#{busy_count} "
        end

        logger.debug log_msg unless log_msg.empty?
      end
    end
  end
end
