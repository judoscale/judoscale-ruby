# frozen_string_literal: true

require "judoscale/logger"

module Judoscale
  module WorkerAdapters
    class Base
      include Judoscale::Logger
      include Singleton

      # Adapter class name extracted from the full class name.
      # Example: Judoscale::WorkerAdapters::MyAdapter.adapter_name => 'MyAdapter'
      def self.adapter_name
        @_adapter_name ||= name.split("::").last
      end

      # Underscored version of the adapter name used as identifier.
      # Example: Judoscale::WorkerAdapters::MyAdapter.adapter_identifier => 'my_adapter'
      def self.adapter_identifier
        @_adapter_identifer ||= adapter_name.scan(/[A-Z][a-z]+/).join("_").downcase
      end

      def self.adapter_config
        Config.instance.public_send(adapter_identifier)
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

      def enabled?
        false
      end

      def collect!(store)
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
          queues &= configured_queues
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

      def track_long_running_jobs?
        adapter_config.track_long_running_jobs
      end
    end
  end
end
