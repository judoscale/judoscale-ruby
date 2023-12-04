# frozen_string_literal: true

require "test_helper"
require "minitest/benchmark"
require "judoscale/sidekiq/metrics_collector"

class CollectBenchmark < Minitest::Benchmark
  BATCH_SIZE = 1_000
  MAX_RETRIES = 3

  # performance assertions will iterate over `bench_range`.
  # We'll use it to define the number Sidekiq jobs we enqueue in Redis.
  def self.bench_range
    bench_exp 10, 1_000_000 #=> [10, 100, 1000, 10000, 100000, 1000000]
  end

  def setup
    # Override ConfigHelpers and log to STDOUT for debugging
    Judoscale::Config.instance.reset

    @collector = Judoscale::Sidekiq::MetricsCollector.new
    sidekiq_args = BATCH_SIZE.times.map { [] }

    puts "Sidekiq verison: #{Sidekiq::VERSION}"
    puts "Redis version: #{Sidekiq.redis(&:info)["redis_version"]}"

    # We need to prepare data for all benchmarks in advance. Each benchmark
    # will target an isolated Redis DB with a different number of jobs.
    self.class.bench_range.each do |n|
      with_isolated_redis(n) do
        Sidekiq.redis(&:flushdb)

        (n / BATCH_SIZE).times do |i|
          attempts = 0

          begin
            Sidekiq::Client.push_bulk "class" => "Foo", "args" => sidekiq_args
          rescue => e
            attempts += 1
            puts "RESCUED batch #{i}, attempt #{attempts}: #{e.class}, #{e.message}"

            # Give the connection a moment to recover
            sleep(1)

            retry if attempts < MAX_RETRIES
            raise e
          end
        end
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
    # n is in powers of 10, but we want to use a database number in the range 0-9
    db_number = Math.log10(n).to_i

    if Sidekiq.respond_to?(:default_configuration)
      # `new_redis_pool` will use the configuration from Sidekiq.default_configuration
      Sidekiq.default_configuration.redis = {db: db_number}
      pool = Sidekiq.default_configuration.new_redis_pool 10, "bench-#{n}"
      Sidekiq::Client.via(pool, &block)
    else
      # For older (pre-capsule) versions of Sidekiq
      Sidekiq.redis = {db: db_number}
      block.call
    end
  end
end
