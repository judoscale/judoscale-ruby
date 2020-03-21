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
      # Rails logger defaults to DEBUG level in production, but I don't want
      # to be chatty by default.
      logger.debug(*args) if ENV['RAILS_AUTOSCALE_DEBUG'] == 'true'
    end

    def method_missing(name, *args, &block)
      logger.send name, *args, &block
    end
  end
end
