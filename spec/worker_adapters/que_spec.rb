# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/worker_adapters/que'
require 'rails_autoscale_agent/store'
require 'que'

module RailsAutoscaleAgent
  describe WorkerAdapters::Que do
    def enqueue(queue, run_at)
      ActiveRecord::Base.connection.insert <<~SQL
        INSERT INTO que_jobs (queue, run_at)
        VALUES ('#{queue}', '#{run_at.iso8601(6)}')
      SQL
    end

    subject { described_class.instance }

    describe "#enabled?" do
      specify { expect(subject.enabled?).to be_truthy }
    end

    describe "#collect!" do
      before { described_class.queues = Set.new }
      before { ActiveRecord::Base.connection.execute("DELETE FROM que_jobs") }
      after { Store.instance.instance_variable_set '@measurements', [] }

      it "collects latency for each queue" do
        store = Store.instance
        enqueue('default', Time.now - 11)
        enqueue('high', Time.now - 22.2222)

        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to be_within(5).of 11000
        expect(store.measurements[1].queue_name).to eq 'high'
        expect(store.measurements[1].value).to be_within(5).of 22222
      end

      it "collects metrics for jobs without a queue name" do
        store = Store.instance
        enqueue(nil, Time.now - 11)

        subject.collect! store

        expect(store.measurements.size).to eq 1
        expect(store.measurements[0].queue_name).to eq '[unnamed]'
        expect(store.measurements[0].value).to be_within(5).of 11000
      end
    end
  end
end
