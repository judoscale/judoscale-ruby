# frozen_string_literal: true

require "test_helper"
require "minitest/benchmark"
require "judoscale/sidekiq/metrics_collector"

class CollectWithManyReportersBenchmark < Minitest::Benchmark
  BATCH_SIZE = 1_000
  QUEUES = %w[one two three four five six seven eight nine ten]

  # performance assertions will iterate over `bench_range`.
  # The values here don't matter—we just want several iterations through the benchmark.
  def self.bench_range
    (0..4).to_a
  end

  def setup
    # Enqueue jobs on several queues
    sidekiq_args = BATCH_SIZE.times.map { [] }
    QUEUES.each do |queue|
      Sidekiq::Client.push_bulk "class" => "Foo", "args" => sidekiq_args, "queue" => queue
    end

    # Prepare a collector for each benchmark iteration
    @collectors = {}
    self.class.bench_range.each do |n|
      @collectors[n] = Judoscale::Sidekiq::MetricsCollector.new
    end
  end

  def bench_collect
    validation = proc do |_, times|
      # The first collector should take the longest, since the rest will be
      # no-ops after checking for `collected_recently?`.
      first, *rest = times
      assert_operator first, :>, rest.max
    end

    assert_performance validation do |n|
      @collectors.fetch(n).collect
    end
  end
end
