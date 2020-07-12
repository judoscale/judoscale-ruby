# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  describe Logger do
    LOGFILE = 'tmp/logger_spec_output.log'

    include Logger

    def messages
      File.read(LOGFILE).chomp.lines
    end

    let(:original_logger) { ::Logger.new(LOGFILE) }

    before { `mkdir -p tmp && rm -f #{LOGFILE}` }
    before { Config.instance.logger = original_logger }

    describe '#info' do
      it 'delegates to the original logger, prepending RailsAutoscale' do
        logger.info 'some info'
        expect(messages.last).to include 'INFO -- : [RailsAutoscale] some info'
      end

      it 'can be silenced via config' do
        use_config quiet: true do
          logger.info 'some info'
          expect(messages.last).to_not include 'INFO -- : [RailsAutoscale] some info'
        end
      end
    end

    describe '#debug' do
      it 'silences debug logs by default' do
        logger.debug 'silence'
        expect(messages.last).to_not include 'silence'
      end

      context 'configured to allow debug logs' do
        around { |example| use_env({'RAILS_AUTOSCALE_DEBUG' => 'true'}, &example) }

        it "includes debug logs if the mail logger.level is DEBUG" do
          original_logger.level = "DEBUG"
          logger.debug 'some noise'
          expect(messages.last).to include 'DEBUG -- : [RailsAutoscale] some noise'
        end

        it "includes debug logs if the mail logger.level is INFO" do
          original_logger.level = "INFO"
          logger.debug 'some noise'
          expect(messages.last).to include 'INFO -- : [RailsAutoscale] [DEBUG] some noise'
        end
      end
    end
  end
end
