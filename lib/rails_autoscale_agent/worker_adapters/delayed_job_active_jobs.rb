# frozen_string_literal: true

require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  module WorkerAdapters
    class DelayedJobActiveJobs
      include RailsAutoscaleAgent::Logger
      include Singleton

      def enabled?
        latency_for_active_jobs && defined?(::Delayed::Job) && defined?(::Delayed::Backend::ActiveRecord)
      end

      def collect!(store)
        log_msg = String.new
        sql = <<~SQL
          SELECT DISTINCT COALESCE(queue, 'default')
          FROM delayed_jobs
          WHERE locked_at IS NOT NULL
          AND locked_by IS NOT NULL
          AND failed_at IS NULL
        SQL

        queues_with_active_jobs = ActiveRecord::Base.connection.select_rows(sql).flatten

        # For each queue with an active job, add a fake latency metric.
        # This can be optionally used to prevent Rails Autoscale from downscaling,
        # which can terminate long-running jobs.
        queues_with_active_jobs.each do |queue|
          store.push latency_for_active_jobs, Time.now, queue
          log_msg << "dj-active-jobs.#{queue}=#{latency_for_active_jobs} "
        end

        logger.debug log_msg unless log_msg.empty?
      end

      private

      def latency_for_active_jobs
        Config.instance.latency_for_active_jobs
      end
    end
  end
end
