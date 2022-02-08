# frozen_string_literal: true

require "test_helper"
require "delayed_job_active_record"
require "judoscale/worker_adapters/delayed_job"
require "judoscale/store"

class Delayable
  def perform
  end
end

module Judoscale
  describe WorkerAdapters::DelayedJob do
    subject { WorkerAdapters::DelayedJob.instance }

    describe "#enabled?" do
      specify { _(subject).must_be :enabled? }
    end

    describe "#collect!" do
      let(:store) { Store.instance }

      after {
        ActiveRecord::Base.connection.execute("DELETE FROM delayed_jobs")
        subject.clear_queues
        store.clear
      }

      it "collects latency for each queue" do
        Delayable.new.delay(queue: "default").perform
        sleep 0.15
        Delayable.new.delay(queue: "high").perform

        subject.collect! store

        _(store.measurements.size).must_equal 2
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_be_within_delta 150, 10
        _(store.measurements[0].metric).must_equal :qt
        _(store.measurements[1].queue_name).must_equal "high"
        _(store.measurements[1].value).must_be_within_delta 0, 5
        _(store.measurements[1].metric).must_equal :qt
      end

      it "reports for known queues that have no enqueued jobs" do
        Delayable.new.delay(queue: "default").perform

        subject.collect! store

        _(store.measurements.size).must_equal 1

        ActiveRecord::Base.connection.execute("DELETE FROM delayed_jobs")
        subject.collect! store

        _(store.measurements.size).must_equal 2
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[1].queue_name).must_equal "default"
      end

      it "ignores future jobs" do
        Delayable.new.delay(queue: "default", run_at: Time.now + 10).perform

        subject.collect! store

        _(store.measurements.size).must_equal 1
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_equal 0
      end

      it "always collects for the default queue" do
        subject.collect! store

        _(store.measurements.size).must_equal 1
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_equal 0
      end

      it "collects metrics for jobs without a queue name" do
        Delayable.new.delay.perform

        subject.collect! store

        _(store.measurements.size).must_equal 1
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_be_within_delta 0, 5
      end

      it "logs debug information for each queue being collected" do
        use_config debug: true do
          Delayable.new.delay(queue: "default").perform

          subject.collect! store

          _(log_string).must_match %r{dj-qt.default=\d+ms}
          _(log_string).wont_match %r{dj-busy}
        end
      end

      it "tracks long running jobs when the configuration is enabled" do
        use_adapter_config :delayed_job, track_long_running_jobs: true do
          %w[default default high].each_with_index { |queue, index|
            Delayable.new.delay(queue: queue).perform
            # Create a new worker to simulate "reserving/locking" the next available job for running.
            # Setting a different name ensures each worker will lock a different job.
            Delayed::Worker.new.tap { |w| w.name = "dj_worker_#{index}" }.send(:reserve_job)
          }

          subject.collect! store

          _(store.measurements.size).must_equal 4
          _(store.measurements[1].value).must_equal 2
          _(store.measurements[1].queue_name).must_equal "default"
          _(store.measurements[1].metric).must_equal :busy
          _(store.measurements[3].value).must_equal 1
          _(store.measurements[3].queue_name).must_equal "high"
          _(store.measurements[3].metric).must_equal :busy
        end
      end

      it "logs debug information about long running jobs being collected" do
        use_config debug: true do
          use_adapter_config :delayed_job, track_long_running_jobs: true do
            Delayable.new.delay(queue: "default").perform
            Delayed::Worker.new.send(:reserve_job)

            subject.collect! store

            _(log_string).must_match %r{dj-qt.default=.+ dj-busy.default=1}
          end
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high].each { |queue|
          Delayable.new.delay(queue: queue).perform
        }

        subject.collect! store

        _(store.measurements.size).must_equal 1
        _(store.measurements[0].queue_name).must_equal "default"
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        use_adapter_config :delayed_job, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          %W[low default high low-#{SecureRandom.uuid}].each { |queue|
            Delayable.new.delay(queue: queue).perform
          }

          subject.collect! store

          _(store.measurements.size).must_equal 2
          _(store.measurements[0].queue_name).must_equal "low"
          _(store.measurements[1].queue_name).must_be :start_with?, "low-"
        end
      end

      it "collects metrics only from the configured queues if the configuration is present, ignoring the queue filter" do
        use_adapter_config :delayed_job, queues: %w[low], queue_filter: ->(queue_name) { queue_name != "low" } do
          %w[low default high].each { |queue| Delayable.new.delay(queue: queue).perform }

          subject.collect! store

          _(store.measurements.size).must_equal 1
          _(store.measurements[0].queue_name).must_equal "low"
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        use_adapter_config :delayed_job, max_queues: 2 do
          %w[low default high].each { |queue| Delayable.new.delay(queue: queue).perform }

          subject.collect! store

          _(store.measurements.size).must_equal 2
          _(store.measurements[0].queue_name).must_equal "low"
          _(store.measurements[1].queue_name).must_equal "high"
          _(log_string).must_match %r{DelayedJob metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
