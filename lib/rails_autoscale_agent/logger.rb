# frozen_string_literal: true

require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  module Logger
    def logger
      @logger ||= Config.instance.logger.tap do |logger|
        logger.extend(FakeTaggedLogging) unless logger.respond_to?(:tagged)
      end
    end

    module FakeTaggedLogging
      def tagged(*tags)
        # NOTE: Quack like ActiveSupport::TaggedLogging, but don't reimplement
        yield self
      end
    end
  end
end
