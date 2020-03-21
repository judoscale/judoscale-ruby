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

    let(:original) { FakeLogger.new }
    before { Config.instance.logger = original }

    describe '#info' do
      it 'delegates to the original logger' do
        logger.info 'INFO'
        expect(original.msgs[:info]).to eq ['INFO']
      end
    end

    describe '#debug' do
      it 'silences debug logs by default' do
        logger.debug 'SILENCE'
        expect(original.msgs[:debug]).to eq []
      end

      it 'can be configured to allow debug logs' do
        use_env('RAILS_AUTOSCALE_DEBUG' => 'true') do
          logger.debug 'NOISE'
          expect(original.msgs[:debug]).to eq ['NOISE']
        end
      end

      it 'does not affect the original logger' do
        # require 'pry'; binding.pry
        logger.debug 'LOGGER'
        original.debug 'ORIGINAL'
        expect(original.msgs[:debug]).to eq ['ORIGINAL']
      end
    end
  end
end
