# frozen_string_literal: true

require "judoscale/logger"

module Judoscale
  module WorkerAdapters
    class Base
      include Judoscale::Logger
      include Singleton

      def enabled?
        false
      end

      def collect!(store)
      end
    end
  end
end
