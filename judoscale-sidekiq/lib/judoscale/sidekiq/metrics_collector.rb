# frozen_string_literal: true

require "set"
require "judoscale/job_metrics_collector"
require "judoscale/metric"

module Judoscale
  module Sidekiq
    class MetricsCollector < Judoscale::JobMetricsCollector
      # TODO: how to make these shared/
      def self.adapter_name
        @_adapter_name ||= "Sidekiq" # name.split("::").last
      end

      def self.adapter_identifier
        @_adapter_identifer ||= adapter_name.scan(/[A-Z][a-z]+/).join("_").downcase
      end

      def self.adapter_config
        Config.instance.public_send(adapter_identifier)
      end

      def initialize
        super

        log_msg = +"Sidekiq enabled"
        log_msg << " with busy job tracking support" if track_busy_jobs?
        logger.info log_msg
      end

      def queues
        # Track the known queues so we can continue reporting on queues that don't
        # have enqueued jobs at the time of reporting.
        # Assume a "default" queue on all worker adapters so we always report *something*,
        # even when nothing is enqueued.
        @queues ||= Set.new(["default"])
      end

      def queues=(new_queues)
        @queues = filter_queues(new_queues)
      end

      def clear_queues
        @queues = nil
      end

      def collect
        store = []
        log_msg = +""
        queues_by_name = ::Sidekiq::Queue.all.each_with_object({}) do |queue, obj|
          obj[queue.name] = queue
        end

        self.queues |= queues_by_name.keys

        if track_busy_jobs?
          busy_counts = Hash.new { |h, k| h[k] = 0 }
          ::Sidekiq::Workers.new.each do |pid, tid, work|
            busy_counts[work.dig("payload", "queue")] += 1
          end
        end

        queues.each do |queue_name|
          queue = queues_by_name.fetch(queue_name) { |name| ::Sidekiq::Queue.new(name) }
          latency_ms = (queue.latency * 1000).ceil
          depth = queue.size

          store.push Metric.new(:qt, latency_ms, Time.now, queue_name)
          store.push Metric.new(:qd, depth, Time.now, queue_name)
          log_msg << "sidekiq-qt.#{queue_name}=#{latency_ms}ms sidekiq-qd.#{queue_name}=#{depth} "

          if track_busy_jobs?
            busy_count = busy_counts[queue_name]
            store.push Metric.new(:busy, busy_count, Time.now, queue_name)
            log_msg << "sidekiq-busy.#{queue_name}=#{busy_count} "
          end
        end

        logger.debug log_msg
        store
      end

      private

      def adapter_config
        self.class.adapter_config
      end

      def filter_queues(queues)
        configured_queues = adapter_config.queues

        if configured_queues.empty?
          configured_filter = adapter_config.queue_filter

          if configured_filter.respond_to?(:call)
            queues = queues.select { |queue| configured_filter.call(queue) }
          end
        else
          queues = configured_queues
        end

        queues = filter_max_queues(queues)

        Set.new(queues)
      end

      # Collect up to the configured `max_queues`, skipping the rest.
      # We sort queues by name length before making the cut-off, as a simple heuristic to keep the shorter ones
      # and possibly ignore the longer ones, which are more likely to be dynamically generated for example.
      def filter_max_queues(queues_to_collect)
        queues_size = queues_to_collect.size
        max_queues = adapter_config.max_queues

        if queues_size > max_queues
          logger.warn "#{self.class.adapter_name} metrics reporting only #{max_queues} queues max, skipping the rest (#{queues_size - max_queues})"
          queues_to_collect.sort_by(&:length).first(max_queues)
        else
          queues_to_collect
        end
      end

      def track_busy_jobs?
        adapter_config.track_busy_jobs
      end
    end
  end
end
