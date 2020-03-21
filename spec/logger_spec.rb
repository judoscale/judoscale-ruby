# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  class FakeLogger
    attr_reader :msgs
    def initialize
      @msgs = Hash.new { |h,k| h[k] = [] }
    end
    def debug(msg)
      @msgs[:debug] << msg
    end
    def info(msg)
      @msgs[:info] << msg
    end
  end

  describe Logger do
    include Logger

    let(:original_logger) { FakeLogger.new }
    let(:debug_logger) { FakeLogger.new }
    before { Config.instance.logger = original_logger }
    before { allow(::Logger).to receive(:new) { debug_logger } }

    describe '#info' do
      it 'delegates to the original logger, prepending RailsAutoscale' do
        logger.info 'INFO'
        expect(original_logger.msgs[:info]).to eq ['[RailsAutoscale] INFO']
      end
    end

    describe '#debug' do
      it 'silences debug logs by default' do
        logger.debug 'SILENCE'
        expect(original_logger.msgs[:debug]).to eq []
        expect(debug_logger.msgs[:debug]).to eq []
      end

      it 'can be configured to allow debug logs (sent to a separate logger)' do
        use_env('RAILS_AUTOSCALE_DEBUG' => 'true') do
          logger.debug 'NOISE'
          expect(original_logger.msgs[:debug]).to eq []
          expect(debug_logger.msgs[:debug]).to eq ['[RailsAutoscale] NOISE']
        end
      end

      it 'does not affect the original logger' do
        logger.debug 'LOGGER'
        original_logger.debug 'ORIGINAL'
        expect(original_logger.msgs[:debug]).to eq ['ORIGINAL']
        expect(debug_logger.msgs[:debug]).to eq []
      end
    end
  end
end
