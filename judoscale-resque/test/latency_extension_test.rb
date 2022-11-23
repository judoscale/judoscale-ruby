# frozen_string_literal: true

require "test_helper"
require "judoscale/resque/latency_extension"

module Judoscale
  class RedisStub
    attr_reader :hash

    def initialize
      @hash = Hash.new { |h, k| h[k] = [] }
    end

    def sadd(key, *values)
      hash[key].concat(values)
    end
    alias_method :rpush, :sadd

    def lindex(key, index)
      hash[key][index]
    end

    def lpop(key)
      hash[key].shift
    end

    def pipelined
      yield
    end
  end

  class SampleJob
    def self.perform
    end
  end

  describe Resque::LatencyExtension do
    before {
      @original_redis = ::Resque.redis
      @redis_stub = RedisStub.new
      ::Resque.redis = @redis_stub
    }
    after {
      ::Resque.redis = @original_redis
    }

    it "includes a timestamp value with each job enqueued, used to calculate latency" do
      freeze_time do
        ::Resque.enqueue_to "default", SampleJob

        item = ::Resque.pop("default")
        _(item).must_equal({"class" => "Judoscale::SampleJob", "args" => [], "timestamp" => Time.now.utc.to_f})
      end
    end

    it "calculates latency based on the oldest item in the queue" do
      now = Time.now.utc

      [now, now + 12, now + 18].each { |enqueue_time|
        freeze_time(enqueue_time) { ::Resque.enqueue_to "default", SampleJob }
      }

      freeze_time now + 30 do
        latency = ::Resque.latency("default")
        _(latency).must_be_within_delta 30.0, 0.005
      end

      freeze_time now + 55.5 do
        latency = ::Resque.latency("default")
        _(latency).must_be_within_delta 55.5, 0.005
      end

      # Removing the oldest item to verify it uses the second enqueued item to calculate latency.
      ::Resque.pop("default")

      freeze_time now + 60 do
        latency = ::Resque.latency("default")
        _(latency).must_be_within_delta 48.0, 0.005
      end
    end

    it "calculates 0 latency for previously enqueued items that have no timestamp" do
      ::Resque.enqueue_to "default", SampleJob

      @redis_stub.hash.fetch("resque:queue:default").map! { |item|
        item = ::Resque.decode(item)
        item.delete("timestamp")
        ::Resque.encode(item)
      }

      freeze_time Time.now.utc + 60 do
        latency = ::Resque.latency("default")
        _(latency).must_equal 0.0
      end
    end

    it "calculates 0 latency when there are no items in the queue" do
      latency = ::Resque.latency("default")
      _(latency).must_equal 0.0
    end
  end
end
