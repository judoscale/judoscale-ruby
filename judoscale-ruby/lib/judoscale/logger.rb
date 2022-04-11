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
    TAG = "Judoscale"

    %w[ERROR WARN INFO DEBUG].each do |severity_name|
      severity_level = ::Logger::Severity.const_get(severity_name)

      define_method(severity_name.downcase) do |*messages|
        if log_level.nil?
          logger.add(severity_level) { tag(messages) }
        elsif severity_level >= log_level
          if severity_level >= logger.level
            logger.add(severity_level) { tag(messages) }
          else
            logger.add(logger.level) { tag(messages, tag_level: severity_name) }
          end
        end
      end
    end

    private

    def tag(msgs, tag_level: nil)
      tag = +"[#{TAG}]"
      tag << " [#{tag_level}]" if tag_level
      msgs.map { |msg| "#{tag} #{msg}" }.join("\n")
    end
  end
end
