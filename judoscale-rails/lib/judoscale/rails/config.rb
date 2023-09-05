require "judoscale/config"

module Judoscale
  module Rails
    module Config
      attr_accessor :start_reporter_after_initialize

      def reset
        super
        @start_reporter_after_initialize = true
      end
    end

    ::Judoscale::Config.prepend Config
  end
end
