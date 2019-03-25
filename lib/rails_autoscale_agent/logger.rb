# frozen_string_literal: true

require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  module Logger
    def logger
      @logger ||= Config.instance.logger.tap do |logger|
        logger.extend(FakeTaggedLogging) unless logger.respond_to?(:tagged)
        logger.extend(ConditionalDebugLogging)
      end
    end

    module FakeTaggedLogging
      def tagged(*tags)
        # NOTE: Quack like ActiveSupport::TaggedLogging, but don't reimplement
        yield self
      end
    end

    module ConditionalDebugLogging
      def debug(*args)
        # Rails logger defaults to DEBUG level in production, but I don't want
        # to be chatty by default.
        super if ENV['RAILS_AUTOSCALE_LOG_LEVEL'] == 'DEBUG'
      end
    end
  end
end
