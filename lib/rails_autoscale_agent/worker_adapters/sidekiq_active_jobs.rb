# frozen_string_literal: true

require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  module WorkerAdapters
    class SidekiqActiveJobs
      include RailsAutoscaleAgent::Logger
      include Singleton

      def enabled?
        return false unless latency_for_active_jobs
        require 'sidekiq/api'
        logger.info "SidekiqActiveJobs enabled"
        true
      rescue LoadError
        false
      end

      def collect!(store)
        log_msg = String.new
        workers_by_queue = ::Sidekiq::Workers.new.group_by do |process_id, thread_id, work|
          work.dig 'payload', 'queue'
        end

        ::Sidekiq::Queue.all.each do |queue|
          workers = Array(workers_by_queue[queue.name])

          # If there are active running jobs on this queue, add a fake latency metric.
          # This will prevent Rails Autoscale from downscaling, which potentially kills long-running jobs.
          if workers.any?
            store.push latency_for_active_jobs, Time.now, queue.name
            log_msg << "sidekiq-active-jobs.#{queue.name}=#{latency_for_active_jobs} "
          end
        end

        logger.debug log_msg unless log_msg.empty?
      end

      private

      def latency_for_active_jobs
        Config.instance.sidekiq_latency_for_active_jobs
      end
    end
  end
end
