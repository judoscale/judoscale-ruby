# frozen_string_literal: true

require 'rails_autoscale_agent/config'
require 'logger'

module RailsAutoscaleAgent
  module Logger
    def logger
      @logger ||= LoggerProxy.new(Config.instance.logger)
    end
  end

  class LoggerProxy < Struct.new(:logger)
    TAG = '[RailsAutoscale]'

    def error(msg)
      logger.error tag(msg)
    end

    def warn(msg)
      logger.warn tag(msg)
    end

    def info(msg)
      logger.info tag(msg) unless Config.instance.quiet?
    end

    def debug(msg)
      # Silence debug logs by default to avoiding being overly chatty (Rails logger defaults
      # to DEBUG level in production). Setting RAILS_AUTOSCALE_DEBUG=true enables debug logs,
      # even if the underlying logger severity level is INFO.
      if Config.instance.debug?
        if logger.respond_to?(:debug?) && logger.debug?
          logger.debug tag(msg)
        elsif logger.respond_to?(:info?) && logger.info?
          logger.info tag("[DEBUG] #{msg}")
        end
      end
    end

    private

    def tag(msg)
      "#{TAG} #{msg}"
    end
  end
end
