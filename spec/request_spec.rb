# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/request'
require 'rails_autoscale_agent/config'

module RailsAutoscaleAgent
  describe Request do
    let(:request) { Request.new(env, config) }
    let(:env) { {} }
    let(:config) { Config.instance }

    describe "#queue_time" do
      it "handles X_REQUEST_START in integer milliseconds (Heroku)" do
        started_at = Time.now - 2
        ended_at = started_at + 1
        env['HTTP_X_REQUEST_START'] = (started_at.to_f * 1000).to_i.to_s

        expect(request.queue_time(ended_at)).to be_within(1).of(1000)
      end

      it "handles X_REQUEST_START in seconds with fractional milliseconds (nginx)" do
        started_at = Time.now - 2
        ended_at = started_at + 1
        env['HTTP_X_REQUEST_START'] = "t=#{format '%.3f', started_at.to_f}"

        expect(request.queue_time(ended_at)).to be_within(1).of(1000)
      end
    end
  end
end
