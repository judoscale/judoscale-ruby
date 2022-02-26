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

    %w[ERROR WARN INFO].each do |level|
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

        it "respects the configured log_level" do
          use_config log_level: :unknown do
            logger.public_send method_name, "some message"
            _(messages).wont_include "some message"
          end
        end

        it "respects the level set by the original logger" do
          original_logger.level = ::Logger::Severity::UNKNOWN
          logger.public_send method_name, "some message"
          _(messages).wont_include "some message"
        end
      end
    end

    describe "#debug" do
      it "delegates to the original logger, prepending Judoscale and [DEBUG]" do
        logger.debug "some message"
        _(messages).must_include "DEBUG -- : [Judoscale] [DEBUG] some message"
      end

      it "allows logging multiple messages in separate lines, all prepending Judoscale and [DEBUG]" do
        logger.debug "some msg", "msg context", "more msg context"
        _(messages).must_include "DEBUG -- : [Judoscale] [DEBUG] some msg\n[Judoscale] [DEBUG] msg context\n[Judoscale] [DEBUG] more msg context"
      end

      it "respects the configured log_level" do
        use_config log_level: :info do
          logger.debug "some message"
          _(messages).wont_include "some message"
        end
      end

      it "logs at the original logger level to ensure debug messages are always logged when enabled" do
        original_logger.level = ::Logger::Severity::INFO
        logger.debug "some message"
        _(messages).must_include "INFO -- : [Judoscale] [DEBUG] some message"
      end
    end
  end
end
