# frozen_string_literal: true

require "judoscale/job_metrics_collector"
require "judoscale/metric"

module Judoscale
  module Shoryuken
    class MetricsCollector < Judoscale::JobMetricsCollector
      SQS_QUEUE_DEPTH_ATTRIBUTE = "ApproximateNumberOfMessages"

      def self.adapter_config
        Judoscale::Config.instance.shoryuken
      end

      def initialize
        super
        self.queues |= ::Shoryuken.ungrouped_queues
      end

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

          # Reach out to SQS client directly to fetch the queue attribute we need to report.
          # Shoryuken has a private `queue_attributes` API to fetch all attributes, this call mimics that.
          sqs_queue_attributes = ::Shoryuken.sqs_client
            .get_queue_attributes(queue_url: queue.url, attribute_names: [SQS_QUEUE_DEPTH_ATTRIBUTE])
          depth = sqs_queue_attributes.attributes[SQS_QUEUE_DEPTH_ATTRIBUTE]

          metrics.push Metric.new(:qd, depth, Time.now, queue_name)
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
