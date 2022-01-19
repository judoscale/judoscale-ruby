# frozen_string_literal: true

require "test_helper"
require "judoscale/logger"

module Judoscale
  describe Logger do
    include Logger

    let(:string_io) { StringIO.new }
    let(:original_logger) { ::Logger.new(string_io) }
    let(:messages) { string_io.string }

    before do
      Config.instance.logger = original_logger
    end

    describe "#error" do
      it "delegates to the original logger, prepending Judoscale" do
        logger.error "some error"
        _(messages).must_include "ERROR -- : [Judoscale] some error"
      end
    end

    describe "#warn" do
      it "delegates to the original logger, prepending Judoscale" do
        logger.warn "some warn"
        _(messages).must_include "WARN -- : [Judoscale] some warn"
      end
    end

    describe "#info" do
      it "delegates to the original logger, prepending Judoscale" do
        logger.info "some info"
        _(messages).must_include "INFO -- : [Judoscale] some info"
      end

      it "can be silenced via config" do
        use_config quiet: true do
          logger.info "some info"
          _(messages).wont_include "INFO -- : [Judoscale] some info"
        end
      end
    end

    describe "#debug" do
      it "silences debug logs by default" do
        logger.debug "silence"
        _(messages).wont_include "silence"
      end

      describe "configured to allow debug logs" do
        before {
          setup_env({"JUDOSCALE_DEBUG" => "true"})
          # Need to reconfigure the logger with the new ENV setup.
          Config.instance.logger = original_logger
        }

        it "includes debug logs if enabled and the main logger.level is DEBUG" do
          original_logger.level = "DEBUG"
          logger.debug "some noise"
          _(messages).must_include "DEBUG -- : [Judoscale] some noise"
        end

        it "includes debug logs if enabled and the main logger.level is INFO" do
          original_logger.level = "INFO"
          logger.debug "some noise"
          _(messages).must_include "INFO -- : [Judoscale] [DEBUG] some noise"
        end
      end
    end
  end
end
