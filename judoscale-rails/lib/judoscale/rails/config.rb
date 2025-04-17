require "judoscale/config"

module Judoscale
  module Rails
    module Config
      attr_accessor :start_reporter_after_initialize, :rake_task_ignore_regex, :utilization_enabled, :utilization_interval

      def reset
        super
        @start_reporter_after_initialize = true
        @rake_task_ignore_regex = /assets:|db:/

        @utilization_enabled = ENV["JUDOSCALE_UTILIZATION_ENABLED"] == "true"
        @utilization_interval = (ENV["JUDOSCALE_UTILIZATION_INTERVAL"] || 1.0).to_f
      end
    end

    ::Judoscale::Config.prepend Config
  end
end
