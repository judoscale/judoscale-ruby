# frozen_string_literal: true

require "judoscale/config"
require "logger"

module Judoscale
  module Logger
    def logger
      @logger ||= LoggerProxy.new(Config.instance.logger, Config.instance.log_level)
    end
  end

  class LoggerProxy < Struct.new(:logger, :log_level)
    TAG = "[Judoscale]"
    DEBUG_TAG = " [DEBUG]"

    %w[ERROR WARN INFO].each do |severity_name|
      severity_level = ::Logger::Severity.const_get(severity_name)

      define_method(severity_name.downcase) do |*messages|
        if log?(severity_level)
          logger.add(severity_level) { tag(messages) }
        end
      end
    end

    def debug(*messages)
      severity_level = ::Logger::Severity::DEBUG

      if log?(severity_level)
        if log_level.nil?
          logger.add(severity_level) { tag(messages, debug: true) }
        else
          logger.add(logger.level) { tag(messages, debug: true) }
        end
      end
    end

    private

    def log?(severity_level)
      log_level.nil? || severity_level >= log_level
    end

    def tag(msgs, debug: false)
      msgs.map { |msg| "#{TAG}#{DEBUG_TAG if debug} #{msg}" }.join("\n")
    end
  end
end
