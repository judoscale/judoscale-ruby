# frozen_string_literal: true

require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  module Logger
    def logger
      @logger ||= LoggerProxy.new(Config.instance.logger)
    end
  end

  class LoggerProxy < Struct.new(:logger)
    def debug(*args)
      # Silence debug logs by default to avoiding being overly chatty (Rails logger defaults
      # to DEBUG level in production).
      # This uses a separate logger so that RAILS_AUTOSCALE_DEBUG
      # shows debug logs regardless of Rails log level.
      debug_logger.debug(*args) if ENV['RAILS_AUTOSCALE_DEBUG'] == 'true'
    end

    def debug_logger
      @debug_loggers ||= ::Logger.new(STDOUT)
    end

    def method_missing(name, *args, &block)
      logger.send name, *args, &block
    end
  end
end
