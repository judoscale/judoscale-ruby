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

      def collect
        metrics = []
        time = Time.now.utc
        self.queues |= ::Shoryuken.ungrouped_queues

        queues.each do |queue_name|
          queue = ::Shoryuken::Client.queues(queue_name)

          # Reach out to SQS client directly to fetch the queue attribute we need to report.
          # Shoryuken has a private `queue_attributes` API to fetch all attributes, this call mimics that.
          sqs_queue_attributes = ::Shoryuken.sqs_client
            .get_queue_attributes(queue_url: queue.url, attribute_names: [SQS_QUEUE_DEPTH_ATTRIBUTE])
          depth = sqs_queue_attributes.attributes[SQS_QUEUE_DEPTH_ATTRIBUTE]

          metrics.push Metric.new(:qd, depth, time, queue_name)
        end

        log_collection(metrics)
        metrics
      end
    end
  end
end
