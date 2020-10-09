# frozen_string_literal: true

require 'rails_autoscale_agent/logger'
require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  module WorkerAdapters
    class DelayedJobBusyJobs
      include RailsAutoscaleAgent::Logger
      include Singleton

      def enabled?
        return false unless Config.instance.track_long_running_jobs
        defined?(::Delayed::Job) && defined?(::Delayed::Backend::ActiveRecord)
      end

      def collect!(store)
        log_msg = String.new
        sql = <<~SQL
          SELECT COALESCE(queue, 'default'), count(*)
          FROM delayed_jobs
          WHERE locked_at IS NOT NULL
          AND locked_by IS NOT NULL
          AND failed_at IS NULL
          GROUP BY 1
        SQL

        busy_count_by_queue = Hash[ActiveRecord::Base.connection.select_rows(sql)]

        busy_count_by_queue.each do |queue, busy_count|
          store.push busy_count, Time.now, queue, :busy
          log_msg << "dj-busy-jobs.#{queue}=#{busy_count} "
        end

        logger.debug log_msg unless log_msg.empty?
      end
    end
  end
end
