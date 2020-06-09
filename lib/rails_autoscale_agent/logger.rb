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

    %w[info warn error].each do |name|
      define_method name do |msg|
        logger.send name, tag(msg)
      end
    end

    def debug(msg)
      # Silence debug logs by default to avoiding being overly chatty (Rails logger defaults
      # to DEBUG level in production).
      # This uses a separate logger so that RAILS_AUTOSCALE_DEBUG
      # shows debug logs regardless of Rails log level.
      debug_logger.debug tag(msg) if ENV['RAILS_AUTOSCALE_DEBUG'] == 'true'
    end

    private

    def debug_logger
      @debug_loggers ||= ::Logger.new(STDOUT)
    end

    def tag(msg)
      "#{TAG} #{msg}"
    end
  end
end
