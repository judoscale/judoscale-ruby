# frozen_string_literal: true

require "test_helper"
require "judoscale/logger"

module Judoscale
  describe Logger do
    include Logger

    let(:string_io) { StringIO.new }
    let(:original_logger) { ::Logger.new(string_io) }
    let(:messages) { string_io.string }

    before {
      Judoscale.configure { |config| config.logger = original_logger }
    }

    %w[ERROR WARN INFO DEBUG FATAL].each do |level|
      method_name = level.downcase

      describe "##{method_name}" do
        it "delegates to the original logger, prepending Judoscale" do
          logger.public_send method_name, "some message"
          _(messages).must_include "#{level} -- : [Judoscale] some message"
        end

        it "allows logging multiple messages in separate lines, all prepending Judoscale" do
          logger.public_send method_name, "some msg", "msg context", "more msg context"
          _(messages).must_include "#{level} -- : [Judoscale] some msg\n[Judoscale] msg context\n[Judoscale] more msg context"
        end

        it "logs at the given level without tagging the level when both the configured log level and the underlying logger level permit" do
          original_logger.level = ::Logger::Severity::DEBUG

          use_config log_level: level do
            logger.public_send method_name, "some message"
            _(messages).must_include "#{level} -- : [Judoscale] some message"
          end
        end

        if method_name != "fatal"
          it "respects the configured log_level" do
            use_config log_level: :fatal do
              logger.public_send method_name, "some message"
              _(messages).wont_include "some message"
            end
          end

          it "respects the configured log_level even if the logger has been initialized" do
            logger.debug "this triggers the logger initialization"

            use_config log_level: :fatal do
              logger.public_send method_name, "some message"
              _(messages).wont_include "some message"
            end
          end

          it "respects the level set by the original logger when the log level config is not overridden" do
            original_logger.level = ::Logger::Severity::FATAL

            logger.public_send method_name, "some message"
            _(messages).wont_include "some message"
          end

          it "logs at the underlying logger level tagging with the given level when the configured log level is lower, to ensure messages are always logged" do
            original_logger.level = ::Logger::Severity::FATAL

            use_config log_level: level do
              logger.public_send method_name, "some message"
              _(messages).must_include "FATAL -- : [Judoscale] [#{level}] some message"
            end
          end
        end
      end
    end

    class LoggerSymbol < ::Logger
      def level
        ::Logger::SEV_LABEL[super].downcase.to_sym
      end

      def level=(new_level)
        super Judoscale::Config.coerce_log_level(new_level)
      end

      def add(severity, message = nil, *)
        # Bypass the severity/level check inside Logger that'd fail with Integer vs symbol too.
        # Log everything.
        @logdev.write("LEVEL=#{level} SEVERITY=#{severity} #{message || yield}")
        true
      end
      alias_method :log, :add
    end

    it "gracefully handles logger level using symbols/strings (such as rails-semantic-logger)" do
      original_logger = LoggerSymbol.new(string_io)
      original_logger.level = :info

      use_config logger: original_logger, log_level: :warn do
        logger.info "some info"
        _(messages).wont_include "some info"

        logger.warn "some warning"
        _(messages).must_include "LEVEL=info SEVERITY=2 [Judoscale] some warning"

        original_logger.level = :ERROR
        logger.warn "other warning"

        _(messages).must_include "LEVEL=error SEVERITY=error [Judoscale] [WARN] other warning"
      end
    end
  end
end
