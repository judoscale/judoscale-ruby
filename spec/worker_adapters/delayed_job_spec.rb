# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/worker_adapters/delayed_job'
require 'rails_autoscale_agent/store'
require 'delayed_job'

module ActiveRecord
  module Base
    cattr_accessor :connection

    class Connection
      attr_accessor :rows

      def select_rows(query)
        rows
      end
    end

    self.connection = Connection.new
  end
end

Job = Struct.new(:queue)

module RailsAutoscaleAgent
  describe WorkerAdapters::DelayedJob do
    subject { described_class.instance }

    describe "#enabled?" do
      specify { expect(subject.enabled?).to be_truthy }
    end

    describe "#collect!" do
      before { described_class.queues = Set.new }
      after { Store.instance.instance_variable_set '@measurements', [] }

      it "collects latency for each queue" do
        store = Store.instance
        ActiveRecord::Base.connection.rows = [
          ['low', Time.now - 11],
          ['high', Time.now - 22.2222],
        ]

        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements[0].value).to be_within(2).of 11000
        expect(store.measurements[0].queue_name).to eq 'low'
        expect(store.measurements[1].value).to be_within(2).of 22222
        expect(store.measurements[1].queue_name).to eq 'high'
      end

      it "reports for queues that have no enqueued jobs" do
        store = Store.instance
        ActiveRecord::Base.connection.rows = [['low', Time.now - 11]]

        Delayed::Worker.lifecycle.run_callbacks(:enqueue, Job.new('low')) { }
        subject.collect! store

        expect(store.measurements.size).to eq 1

        ActiveRecord::Base.connection.rows = []

        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements[0].value).to be_within(2).of 11000
        expect(store.measurements[0].queue_name).to eq 'low'
        expect(store.measurements[1].value).to eq 0
        expect(store.measurements[1].queue_name).to eq 'low'
      end

      it "collects metrics for jobs without a queue name" do
        store = Store.instance
        ActiveRecord::Base.connection.rows = [[nil, Time.now - 11]]

        subject.collect! store

        expect(store.measurements.size).to eq 1
        expect(store.measurements[0].value).to be_within(2).of 11000
        expect(store.measurements[0].queue_name).to eq '[unnamed]'
      end

      it "handles string values for run_at" do
        store = Store.instance
        expected_value = (Time.now - Time.parse('2019-12-04T11:44:45Z')) * 1000
        ActiveRecord::Base.connection.rows = [
          ['default', '2019-12-04 11:44:45+00'],
        ]

        subject.collect! store

        expect(store.measurements.size).to eq 1
        expect(store.measurements[0].value).to be_within(2).of expected_value
        expect(store.measurements[0].queue_name).to eq 'default'
      end
    end
  end
end
