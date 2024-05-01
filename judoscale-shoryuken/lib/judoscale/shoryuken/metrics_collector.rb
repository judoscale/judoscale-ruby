# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/metric"

module Judoscale
  module Shoryuken
    class MetricsCollector < Judoscale::JobMetricsCollector
      def self.adapter_config
        Judoscale::Config.instance.shoryuken
      end

      def initialize
        super
        self.queues |= ::Shoryuken.ungrouped_queues
      end

      # TODO: support for busy jobs?
      def collect
        metrics = []
        queues_by_name = Hash.new { |hash, queue_name|
          hash[queue_name] = ::Shoryuken::Client.queues(queue_name)
        }
        # Initialize each queue known by Shoryuken.
        ::Shoryuken.ungrouped_queues.each do |queue_name|
          queues_by_name[queue_name]
        end

        self.queues |= queues_by_name.keys

        queues.each do |queue_name|
          queue = queues_by_name[queue_name]
          # TODO: use public APIs and/or SQS client directly ourselves.
          depth = queue.send(:queue_attributes).attributes["ApproximateNumberOfMessages"]

          metrics.push Metric.new(:qd, depth, Time.now, queue_name)
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
