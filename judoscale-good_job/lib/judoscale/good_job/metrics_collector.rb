# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/job_metrics_collector/active_record_helper"
require "judoscale/metric"

module Judoscale
  module GoodJob
    class MetricsCollector < Judoscale::JobMetricsCollector
      include ActiveRecordHelper

      def self.good_job_v4?
        Gem::Version.new(::GoodJob::VERSION) >= Gem::Version.new("4")
      end

      def self.good_job_base_class
        good_job_v4? ? ::GoodJob::Job : ::GoodJob::Execution
      end

      def self.adapter_config
        Judoscale::Config.instance.good_job
      end

      def self.collect?(config)
        super && ActiveRecordHelper.table_exists_for_model?(good_job_base_class)
      end

      def initialize
        super
        @good_job_base_class = self.class.good_job_base_class
      end

      def collect
        metrics = []
        time = Time.now.utc

        if queues.empty?
          self.queues |= run_silently { @good_job_base_class.distinct.pluck(:queue_name) }
        end

        # Read the oldest pending job and the count and oldest start of running jobs per queue in one scan of
        # unfinished jobs, so busy job tracking adds no queries. Running means performed but not finished, matching GoodJob's
        # `running` scope on v3's Execution and v4.2+'s Job (v4.0-4.1 checked advisory locks).
        # The finished_at condition lets postgres use the indexes.
        rows = run_silently do
          @good_job_base_class
            .where(finished_at: nil)
            .group(:queue_name)
            .pluck(
              :queue_name,
              Arel.sql("min(coalesce(scheduled_at, created_at)) FILTER (WHERE performed_at IS NULL)"),
              Arel.sql("count(*) FILTER (WHERE performed_at IS NOT NULL)"),
              Arel.sql("min(performed_at)")
            )
        end
        oldest_execution_time_by_queue = rows.to_h { |queue, run_at, _, _| [queue, run_at] }
        busy_count_by_queue = rows.to_h { |queue, _, busy_count, _| [queue, busy_count] }
        oldest_performed_at_by_queue = rows.to_h { |queue, _, _, performed_at| [queue, performed_at] }
        self.queues |= rows.map(&:first)

        queues.each do |queue|
          run_at = oldest_execution_time_by_queue[queue]
          # DateTime.parse assumes a UTC string
          run_at = DateTime.parse(run_at) if run_at.is_a?(String)
          latency_ms = run_at ? ((time - run_at) * 1000).ceil : 0
          latency_ms = 0 if latency_ms < 0

          metrics.push Metric.new(:qt, latency_ms, time, queue)

          if track_busy_jobs?
            busy_count = busy_count_by_queue[queue] || 0
            metrics.push Metric.new(:busy, busy_count, time, queue)

            performed_at = oldest_performed_at_by_queue[queue]
            performed_at = DateTime.parse(performed_at) if performed_at.is_a?(String)
            busy_time_ms = performed_at ? ((time - performed_at) * 1000).ceil : 0
            busy_time_ms = 0 if busy_time_ms < 0
            metrics.push Metric.new(:bt, busy_time_ms, time, queue)
          end
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
