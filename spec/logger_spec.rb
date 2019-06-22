# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/logger'

module RailsAutoscaleAgent
  class FakeLogger
    attr_reader :msgs
    def initialize; @msgs = []; end
    def debug(msg)
      @msgs << msg
    end
  end


  describe Logger do
    include Logger

    let(:original) { FakeLogger.new }
    before { Config.instance.logger = original }

    describe '#debug' do
      it 'silences debug logs by default' do
        logger.debug 'SILENCE'
        expect(logger.msgs).to eq []
      end

      it 'can be configured to allow debug logs' do
        use_env('RAILS_AUTOSCALE_LOG_LEVEL' => 'DEBUG') do
          logger.debug 'NOISE'
          expect(logger.msgs).to eq ['NOISE']
        end
      end

      it 'does not affect the original logger' do
        # require 'pry'; binding.pry
        logger.debug 'LOGGER'
        original.debug 'ORIGINAL'
        expect(logger.msgs).to eq ['ORIGINAL']
      end
    end
  end
end
