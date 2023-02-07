# frozen_string_literal: true

require "test_helper"
require "judoscale/good_job/metrics_collector"

class Delayable < ActiveJob::Base
  retry_on StandardError

  def perform(succeed = true)
    raise "boom" unless succeed
  end
end

module Judoscale
  describe GoodJob::MetricsCollector do
    subject { GoodJob::MetricsCollector.new }

    def clear_enqueued_jobs
      ActiveRecord::Base.connection.execute("DELETE FROM good_jobs")
    end

    describe "#collect" do
      after {
        clear_enqueued_jobs
        subject.clear_queues
      }

      it "collects latency for each queue, using the oldest enqueued job" do
        now = Time.now.utc

        freeze_time now - 0.15 do
          Delayable.set(queue: "default").perform_later
        end

        metrics = freeze_time now do
          Delayable.set(queue: "default").perform_later
          Delayable.set(queue: "high").perform_later

          subject.collect
        end

        _(metrics.size).must_equal 2
        _(metrics.map(&:queue_name).sort).must_equal %w[default high]

        metrics_hash = metrics.map { |m| [m.queue_name, m] }.to_h

        _(metrics_hash["default"].queue_name).must_equal "default"
        _(metrics_hash["default"].value).must_be_within_delta 150, 1
        _(metrics_hash["default"].identifier).must_equal :qt
        _(metrics_hash["high"].queue_name).must_equal "high"
        _(metrics_hash["high"].value).must_be_within_delta 0, 1
        _(metrics_hash["high"].identifier).must_equal :qt
      end

      it "always collects for known queues" do
        Delayable.set(queue: "high").perform_later
        ::GoodJob::JobPerformer.new("high").next

        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "high"
        _(metrics[0].value).must_equal 0

        Delayable.set(queue: "default").perform_later

        metrics = subject.collect

        _(metrics.map(&:queue_name).sort).must_equal %w[default high]

        clear_enqueued_jobs
        metrics = subject.collect

        _(metrics.size).must_equal 2
        _(metrics.map(&:queue_name).sort).must_equal %w[default high]
      end

      it "always collects for queues with completed jobs" do
        metrics = subject.collect

        _(metrics).must_be :empty?

        now = Time.now.utc
        freeze_time(now - 0.15) { Delayable.set(queue: "default").perform_later }
        metrics = freeze_time(now) { subject.collect }

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_be_within_delta 150, 1

        ::GoodJob::JobPerformer.new("default").next
        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_equal 0
      end

      it "ignores future jobs" do
        Delayable.set(queue: "default", wait: 10.seconds).perform_later

        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_equal 0
      end

      it "ignores failed jobs waiting on retry" do
        Delayable.set(queue: "default").perform_later(false)
        ::GoodJob::JobPerformer.new("default").next

        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_equal 0
      end

      it "collects metrics for jobs without a queue name" do
        metrics = freeze_time do
          Delayable.perform_later

          subject.collect
        end

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_be_within_delta 0, 1
      end

      it "logs debug information for each queue being collected" do
        use_config log_level: :debug do
          Delayable.set(queue: "default").perform_later

          subject.collect

          _(log_string).must_match %r{good_job-qt.default=\d+ms}
          _(log_string).wont_match %r{good_job-busy}
        end
      end

      it "tracks busy jobs when the configuration is enabled" do
        use_adapter_config :good_job, track_busy_jobs: true do
          Delayable.set(queue: "default").perform_later
          ::GoodJob::Execution.last.update!(performed_at: Time.now.utc)

          metrics = subject.collect

          _(metrics.size).must_equal 2
          _(metrics[1].value).must_equal 1
          _(metrics[1].queue_name).must_equal "default"
          _(metrics[1].identifier).must_equal :busy
        end
      end

      it "logs debug information about busy jobs being collected" do
        use_config log_level: :debug do
          use_adapter_config :good_job, track_busy_jobs: true do
            Delayable.set(queue: "default").perform_later
            ::GoodJob::Execution.last.update!(performed_at: Time.now.utc)

            subject.collect

            _(log_string).must_match %r{good_job-qt.default=.+ good_job-busy.default=1}
          end
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high].each { |queue|
          Delayable.set(queue: queue).perform_later
        }

        metrics = subject.collect

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        use_adapter_config :good_job, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          %W[low default high low-#{SecureRandom.uuid}].each { |queue|
            Delayable.set(queue: queue).perform_later
          }

          metrics = subject.collect

          queue_names = metrics.map(&:queue_name).sort
          _(queue_names.size).must_equal 2
          _(queue_names[0]).must_equal "low"
          _(queue_names[1]).must_be :start_with?, "low-"
        end
      end

      it "collects metrics only from the configured queues if the configuration is present, ignoring the queue filter" do
        use_adapter_config :good_job, queues: %w[low ultra], queue_filter: ->(queue_name) { queue_name != "low" } do
          %w[low default high].each { |queue| Delayable.set(queue: queue).perform_later }

          metrics = subject.collect

          _(metrics.map(&:queue_name)).must_equal %w[low ultra]
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        use_adapter_config :good_job, max_queues: 2 do
          %w[low default high].each { |queue| Delayable.set(queue: queue).perform_later }

          metrics = subject.collect

          _(metrics.map(&:queue_name)).must_equal %w[low high]
          _(log_string).must_match %r{GoodJob metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
