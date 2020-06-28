# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/worker_adapters/delayed_job'
require 'rails_autoscale_agent/store'

class Delayable
  def perform
  end
end

module RailsAutoscaleAgent
  describe WorkerAdapters::DelayedJob do
    subject { described_class.instance }

    describe "#enabled?" do
      specify { expect(subject.enabled?).to be_truthy }
    end

    describe "#collect!" do
      before { subject.queues = nil }
      before { ActiveRecord::Base.connection.execute("DELETE FROM delayed_jobs") }
      after { Store.instance.instance_variable_set '@measurements', [] }

      it "collects latency for each queue" do
        store = Store.instance
        Delayable.new.delay(queue: 'default').perform
        sleep 0.15
        Delayable.new.delay(queue: 'high').perform

        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to be_within(10).of 150
        expect(store.measurements[1].queue_name).to eq 'high'
        expect(store.measurements[1].value).to be_within(5).of 0
      end

      it "reports for known queues that have no enqueued jobs" do
        store = Store.instance
        Delayable.new.delay(queue: 'default').perform

        subject.collect! store

        expect(store.measurements.size).to eq 1

        ActiveRecord::Base.connection.execute("DELETE FROM delayed_jobs")
        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[1].queue_name).to eq 'default'
      end

      it "ignores future jobs" do
        store = Store.instance
        Delayable.new.delay(queue: 'default', run_at: Time.now + 10).perform

        subject.collect! store

        expect(store.measurements.size).to eq 1
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to eq 0
      end

      it "always collects for the default queue" do
        store = Store.instance

        subject.collect! store

        expect(store.measurements.size).to eq 1
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to eq 0
      end

      it "collects metrics for jobs without a queue name" do
        store = Store.instance
        Delayable.new.delay.perform

        subject.collect! store

        expect(store.measurements.size).to eq 1
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to be_within(5).of 0
      end
    end
  end
end
