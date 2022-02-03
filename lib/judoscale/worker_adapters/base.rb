# frozen_string_literal: true

require "judoscale/logger"

module Judoscale
  module WorkerAdapters
    class Base
      include Judoscale::Logger
      include Singleton

      attr_writer :queues

      def queues
        # Track the known queues so we can continue reporting on queues that don't
        # have enqueued jobs at the time of reporting.
        # Assume a "default" queue on all worker adapters so we always report *something*,
        # even when nothing is enqueued.
        @queues ||= Set.new(["default"])
      end

      def enabled?
        false
      end

      def collect!(store)
      end

      private

      def track_long_running_jobs?
        Config.instance.track_long_running_jobs
      end
    end
  end
end
