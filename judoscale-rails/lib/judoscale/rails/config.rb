require "judoscale/config"

module Judoscale
  module Rails
    module Config
      attr_accessor :start_reporter_after_initialize, :rake_task_ignore_regex, :utilization_enabled

      def reset
        super
        @start_reporter_after_initialize = true
        @rake_task_ignore_regex = /assets:|db:/

        @utilization_enabled = ENV["JUDOSCALE_UTILIZATION_ENABLED"] == "true"
      end
    end

    ::Judoscale::Config.prepend Config
  end
end
