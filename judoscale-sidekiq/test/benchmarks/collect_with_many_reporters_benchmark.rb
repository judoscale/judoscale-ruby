# frozen_string_literal: true

require "test_helper"
require "minitest/benchmark"
require "judoscale/sidekiq/metrics_collector"

class CollectWithManyReportersBenchmark < Minitest::Benchmark
  BATCH_SIZE = 1_000
  QUEUES = %w[one two three four five six seven eight nine ten]

  # performance assertions will iterate over `bench_range`.
  # We'll use it to define the number Collector instances running.
  def self.bench_range
    [1, 100]
  end

  def setup
    @collectors = {}
    sidekiq_args = BATCH_SIZE.times.map { [] }

    # Enqueue jobs on several queues
    QUEUES.each do |queue|
      Sidekiq::Client.push_bulk "class" => "Foo", "args" => sidekiq_args, "queue" => queue
    end

    self.class.bench_range.each do |n|
      @collectors[n] = n.times.map { Judoscale::Sidekiq::MetricsCollector.new }
    end

    # Run a collection to prime the cache (what cache?)
    Judoscale::Sidekiq::MetricsCollector.new.collect
  end

  def bench_collect
    validation = proc do |range, times|
      # 100 collectors should take way less than 100x the time of 1 collector.
      # The 50x factor is arbitrary, but it's a good indicator that we're short-circuiting
      # the collection process for redundant collectors.
      assert_operator times.last, :<, times.first * 50
    end

    assert_performance validation do |n|
      @collectors.fetch(n).each do |collector|
        collector.collect
      end
    end
  end
end
