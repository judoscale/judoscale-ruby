# frozen_string_literal: true

require 'active_support/core_ext/module/delegation'
require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  module Logger
    def logger
      @logger ||= LoggerProxy.new(Config.instance.logger)
    end
  end

  class LoggerProxy < Struct.new(:logger)
    def tagged(*tags, &block)
      if logger.respond_to?(:tagged)
        logger.tagged *tags, &block
      else
        # NOTE: Quack like ActiveSupport::TaggedLogging, but don't reimplement
        yield self
      end
    end

    def debug(*args)
      # Rails logger defaults to DEBUG level in production, but I don't want
      # to be chatty by default.
      logger.debug(*args) if ENV['RAILS_AUTOSCALE_LOG_LEVEL'] == 'DEBUG'
    end

    def method_missing(name, *args, &block)
      logger.send name, *args, &block
    end
  end
end
