# frozen_string_literal: true

require 'spec_helper'
require 'judoscale/worker_adapters/que'
require 'judoscale/store'
require 'que'

module Judoscale
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
      before { subject.queues = nil }
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
    end
  end
end
