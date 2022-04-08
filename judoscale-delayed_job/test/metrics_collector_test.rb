# frozen_string_literal: true

require "test_helper"
require "judoscale/delayed_job/metrics_collector"

class Delayable
  def perform
  end
end

module Judoscale
  describe DelayedJob::MetricsCollector do
    subject { DelayedJob::MetricsCollector.new }

    def clear_enqueued_jobs
      ActiveRecord::Base.connection.execute("DELETE FROM delayed_jobs")
    end

    describe "#collect" do
      after {
        clear_enqueued_jobs
        subject.clear_queues
      }

      it "collects latency for each queue" do
        now = Time.now.utc

        freeze_time now - 0.15 do
          Delayable.new.delay(queue: "default").perform
        end

        metrics = freeze_time now do
          Delayable.new.delay(queue: "high").perform

          subject.collect
        end

        _(metrics.size).must_equal 2
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_be_within_delta 150, 1
        _(metrics[0].identifier).must_equal :qt
        _(metrics[1].queue_name).must_equal "high"
        _(metrics[1].value).must_be_within_delta 0, 1
        _(metrics[1].identifier).must_equal :qt
      end

      it "always collects for known queues" do
        metrics = subject.collect

        _(metrics).must_be :empty?

        Delayable.new.delay(queue: "default").perform

        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"

        clear_enqueued_jobs
        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
      end

      it "ignores future jobs" do
        Delayable.new.delay(queue: "default", run_at: Time.now.utc + 10).perform

        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_equal 0
      end

      it "collects metrics for jobs without a queue name" do
        metrics = freeze_time do
          Delayable.new.delay.perform

          subject.collect
        end

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_be_within_delta 0, 1
      end

      it "logs debug information for each queue being collected" do
        use_config log_level: :debug do
          Delayable.new.delay(queue: "default").perform

          subject.collect

          _(log_string).must_match %r{dj-qt.default=\d+ms}
          _(log_string).wont_match %r{dj-busy}
        end
      end

      it "tracks long running jobs when the configuration is enabled" do
        use_adapter_config :delayed_job, track_busy_jobs: true do
          %w[default default high].each_with_index { |queue, index|
            Delayable.new.delay(queue: queue).perform
            # Create a new worker to simulate "reserving/locking" the next available job for running.
            # Setting a different name ensures each worker will lock a different job.
            Delayed::Worker.new.tap { |w| w.name = "dj_worker_#{index}" }.send(:reserve_job)
          }

          metrics = subject.collect

          _(metrics.size).must_equal 4
          _(metrics[1].value).must_equal 2
          _(metrics[1].queue_name).must_equal "default"
          _(metrics[1].identifier).must_equal :busy
          _(metrics[3].value).must_equal 1
          _(metrics[3].queue_name).must_equal "high"
          _(metrics[3].identifier).must_equal :busy
        end
      end

      it "logs debug information about long running jobs being collected" do
        use_config log_level: :debug do
          use_adapter_config :delayed_job, track_busy_jobs: true do
            Delayable.new.delay(queue: "default").perform
            Delayed::Worker.new.send(:reserve_job)

            subject.collect

            _(log_string).must_match %r{dj-qt.default=.+ dj-busy.default=1}
          end
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high].each { |queue|
          Delayable.new.delay(queue: queue).perform
        }

        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        use_adapter_config :delayed_job, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          %W[low default high low-#{SecureRandom.uuid}].each { |queue|
            Delayable.new.delay(queue: queue).perform
          }

          metrics = subject.collect

          _(metrics.size).must_equal 2
          _(metrics[0].queue_name).must_equal "low"
          _(metrics[1].queue_name).must_be :start_with?, "low-"
        end
      end

      it "collects metrics only from the configured queues if the configuration is present, ignoring the queue filter" do
        use_adapter_config :delayed_job, queues: %w[low ultra], queue_filter: ->(queue_name) { queue_name != "low" } do
          %w[low default high].each { |queue| Delayable.new.delay(queue: queue).perform }

          metrics = subject.collect

          _(metrics.map(&:queue_name)).must_equal %w[low ultra]
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        use_adapter_config :delayed_job, max_queues: 2 do
          %w[low default high].each { |queue| Delayable.new.delay(queue: queue).perform }

          metrics = subject.collect

          _(metrics.map(&:queue_name)).must_equal %w[low high]
          _(log_string).must_match %r{DelayedJob metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
