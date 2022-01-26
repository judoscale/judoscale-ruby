# frozen_string_literal: true

require "test_helper"
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

      before {
        subject.queues = nil
        ActiveRecord::Base.connection.execute("DELETE FROM delayed_jobs")
      }
      after { store.clear }

      it "collects latency for each queue" do
        Delayable.new.delay(queue: "default").perform
        sleep 0.15
        Delayable.new.delay(queue: "high").perform

        subject.collect! store

        _(store.measurements.size).must_equal 2
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_be_within_delta 150, 10
        _(store.measurements[1].queue_name).must_equal "high"
        _(store.measurements[1].value).must_be_within_delta 0, 5
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
        end
      end
    end
  end
end
