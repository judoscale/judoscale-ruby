# frozen_string_literal: true

require "test_helper"
require "rails_autoscale/logger"

module RailsAutoscale
  describe Logger do
    include Logger

    let(:string_io) { StringIO.new }
    let(:original_logger) { ::Logger.new(string_io) }
    let(:messages) { string_io.string }

    before {
      RailsAutoscale.configure { |config| config.logger = original_logger }
    }

    %w[ERROR WARN INFO DEBUG].each do |level|
      method_name = level.downcase

      describe "##{method_name}" do
        it "delegates to the original logger, prepending RailsAutoscale" do
          logger.public_send method_name, "some message"
          _(messages).must_include "#{level} -- : [RailsAutoscale] some message"
        end

        it "prepends Judoscale if JUDOSCALE_URL is set" do
          use_env({"JUDOSCALE_URL" => "https://test"}) do
            RailsAutoscale.configure { |config| config.logger = original_logger }
            logger.public_send method_name, "some message"
            _(messages).must_include "#{level} -- : [Judoscale] some message"
          end
        end

        it "allows logging multiple messages in separate lines, all prepending RailsAutoscale" do
          logger.public_send method_name, "some msg", "msg context", "more msg context"
          _(messages).must_include "#{level} -- : [RailsAutoscale] some msg\n[RailsAutoscale] msg context\n[RailsAutoscale] more msg context"
        end

        it "respects the configured log_level" do
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

        it "logs at the given level without tagging the level when both the configured log level and the underlying logger level permit" do
          original_logger.level = ::Logger::Severity::DEBUG

          use_config log_level: level do
            logger.public_send method_name, "some message"
            _(messages).must_include "#{level} -- : [RailsAutoscale] some message"
          end
        end

        it "logs at the underlying logger level tagging with the given level when the configured log level is lower, to ensure messages are always logged" do
          original_logger.level = ::Logger::Severity::FATAL

          use_config log_level: level do
            logger.public_send method_name, "some message"
            _(messages).must_include "FATAL -- : [RailsAutoscale] [#{level}] some message"
          end
        end
      end
    end
  end
end
