# frozen_string_literal: true

require "test_helper"
require "minitest/benchmark"
require "judoscale/sidekiq/metrics_collector"

class CollectBenchmark < Minitest::Benchmark
  # performance assertions will iterate over `bench_range`
  def self.bench_range
    bench_exp 10, 100_000 #=> [10, 100, 1000, 10_000, 100_000]
  end

  def setup
    @collector = Judoscale::Sidekiq::MetricsCollector.new

    # We need to prepare data for all benchmarks in advance. Each benchmark
    # will target an isolated Redis DB with a different number of jobs.
    self.class.bench_range.each do |n|
      with_isolated_redis(n) do
        Sidekiq.redis(&:flushdb)

        # Enqueue n Sidekiq jobs
        sidekiq_args = n.times.map { [] }
        Sidekiq::Client.push_bulk "class" => "DoesNotMatter", "args" => sidekiq_args
      end
    end
  end

  def bench_collect
    # assert_performance_constant needs a VERY high threshold to ever fail.
    assert_performance_constant 0.9999999 do |n|
      with_isolated_redis(n) do
        @collector.collect
      end
    end
  end

  private

  def with_isolated_redis(n, &block)
    # n is in powers of 10, but we want to use a database number in the range 1-9
    db_number = Math.log10(n).to_i

    # `new_redis_pool` will use the configuration from Sidekiq.default_configuration
    Sidekiq.default_configuration.redis = {db: db_number}
    pool = Sidekiq.default_configuration.new_redis_pool 10, "bench-#{n}"
    Sidekiq::Client.via(pool, &block)

    # For older (pre-capsule) versions of Sidekiq
    # Sidekiq.redis = {db: db_number}
  end
end
