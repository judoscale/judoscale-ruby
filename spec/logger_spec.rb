# frozen_string_literal: true

require "spec_helper"
require "judoscale/logger"

module Judoscale
  describe Logger do
    include Logger

    def messages
      string_io.string
    end

    let(:string_io) { StringIO.new }
    let(:original_logger) { ::Logger.new(string_io) }

    before { Config.instance.logger = original_logger }

    describe "#info" do
      it "delegates to the original logger, prepending Judoscale" do
        logger.info "some info"
        expect(messages).to include "INFO -- : [Judoscale] some info"
      end

      it "can be silenced via config" do
        use_config quiet: true do
          logger.info "some info"
          expect(messages).to_not include "INFO -- : [Judoscale] some info"
        end
      end
    end

    describe "#debug" do
      it "silences debug logs by default" do
        logger.debug "silence"
        expect(messages).to_not include "silence"
      end

      context "configured to allow debug logs" do
        around { |example| use_env({"JUDOSCALE_DEBUG" => "true"}, &example) }

        it "includes debug logs if the mail logger.level is DEBUG" do
          original_logger.level = "DEBUG"
          logger.debug "some noise"
          expect(messages).to include "DEBUG -- : [Judoscale] some noise"
        end

        it "includes debug logs if the mail logger.level is INFO" do
          original_logger.level = "INFO"
          logger.debug "some noise"
          expect(messages).to include "INFO -- : [Judoscale] [DEBUG] some noise"
        end
      end
    end
  end
end
