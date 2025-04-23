# frozen_string_literal: true

require "test_helper"
require "judoscale/request_metrics"
require "judoscale/config"

module Judoscale
  describe RequestMetrics do
    let(:request) { RequestMetrics.new(env, config) }
    let(:env) { {} }
    let(:config) { Config.instance }

    describe "#queue_time" do
      it "handles X_REQUEST_START in integer milliseconds (Heroku)" do
        freeze_time do
          started_at = Time.now.utc - 2
          ended_at = started_at + 1
          env["HTTP_X_REQUEST_START"] = (started_at.to_f * 1000).to_i.to_s

          _(request.queue_time(ended_at)).must_equal 1000
        end
      end

      it "handles X_REQUEST_START in seconds with fractional milliseconds (nginx)" do
        freeze_time do
          started_at = Time.now.utc - 2
          ended_at = started_at + 1
          env["HTTP_X_REQUEST_START"] = "t=#{format "%.3f", started_at.to_f}"

          _(request.queue_time(ended_at)).must_be_within_delta 1000, 1
        end
      end

      it "handles X_REQUEST_START in microseconds" do
        freeze_time do
          started_at = Time.now.utc - 2
          ended_at = started_at + 1
          env["HTTP_X_REQUEST_START"] = (started_at.to_f * 1_000_000).to_i.to_s

          _(request.queue_time(ended_at)).must_be_within_delta 1000, 1
        end
      end

      it "handles X_REQUEST_START in nanoseconds" do
        freeze_time do
          started_at = Time.now.utc - 2
          ended_at = started_at + 1
          env["HTTP_X_REQUEST_START"] = (started_at.to_f * 1_000_000_000).to_i.to_s

          _(request.queue_time(ended_at)).must_be_within_delta 1000, 1
        end
      end

      it "subtracts the network time / request body wait available in puma from the queue time" do
        freeze_time do
          started_at = Time.now.utc - 2
          ended_at = started_at + 1
          env["HTTP_X_REQUEST_START"] = (started_at.to_f * 1000).to_i.to_s
          env["puma.request_body_wait"] = 50

          _(request.queue_time(ended_at)).must_equal 950
        end
      end
    end

    describe "#elapsed_time" do
      it "calculates the time taken to run the given block, returning both the time as milliseconds and the result of the block" do
        time, response = request.elapsed_time do
          sleep 0.001
          "something that takes time"
        end

        _(time).must_be_within_delta 1, 0.01
        _(response).must_equal "something that takes time"
      end
    end
  end
end
