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

    describe "#error" do
      it "delegates to the original logger, prepending Judoscale" do
        logger.error "some error"
        _(messages).must_include "ERROR -- : [Judoscale] some error"
      end

      it "allows logging multiple error messages in separate lines, all prepending Judoscale" do
        logger.error "some error", "error context", "more error context"
        _(messages).must_include "ERROR -- : [Judoscale] some error\n[Judoscale] error context\n[Judoscale] more error context"
      end
    end

    describe "#warn" do
      it "delegates to the original logger, prepending Judoscale" do
        logger.warn "some warn"
        _(messages).must_include "WARN -- : [Judoscale] some warn"
      end

      it "allows logging multiple warn messages in separate lines, all prepending Judoscale" do
        logger.warn "some warn", "warn context", "more warn context"
        _(messages).must_include "WARN -- : [Judoscale] some warn\n[Judoscale] warn context\n[Judoscale] more warn context"
      end
    end

    describe "#info" do
      it "delegates to the original logger, prepending Judoscale" do
        logger.info "some info"
        _(messages).must_include "INFO -- : [Judoscale] some info"
      end

      it "allows logging multiple info messages in separate lines, all prepending Judoscale" do
        logger.info "some info", "info context", "more info context"
        _(messages).must_include "INFO -- : [Judoscale] some info\n[Judoscale] info context\n[Judoscale] more info context"
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
          Judoscale.configure { |config| config.debug = true }
        }

        it "includes debug logs if enabled and the main logger.level is DEBUG" do
          original_logger.level = "DEBUG"
          logger.debug "some noise"
          _(messages).must_include "DEBUG -- : [Judoscale] some noise"
        end

        it "allows logging multiple debug messages in separate lines, all prepending Judoscale" do
          original_logger.level = "DEBUG"
          logger.debug "some noise", "more noise"
          _(messages).must_include "DEBUG -- : [Judoscale] some noise\n[Judoscale] more noise"
        end

        it "includes debug logs if enabled and the main logger.level is INFO" do
          original_logger.level = "INFO"
          logger.debug "some noise"
          _(messages).must_include "INFO -- : [Judoscale] [DEBUG] some noise"
        end

        it "allows logging multiple debug messages in separate lines if debug mode is enabled and logger.level is INFO" do
          original_logger.level = "INFO"
          logger.debug "some noise", "more noise"
          _(messages).must_include "INFO -- : [Judoscale] [DEBUG] some noise\n[Judoscale] [DEBUG] more noise"
        end
      end
    end
  end
end
