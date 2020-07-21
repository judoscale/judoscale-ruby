# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/worker_adapters/resque'
require 'rails_autoscale_agent/store'

module RailsAutoscaleAgent
  describe WorkerAdapters::Resque do
    subject { described_class.instance }

    describe "#enabled?" do
      specify { expect(subject.enabled?).to be_truthy }
    end

    describe "#collect!" do
      before { subject.queues = nil }
      after { Store.instance.instance_variable_set '@measurements', [] }

      it "collects latency for each queue" do
        expect(subject.enabled?).to be_truthy

        store = Store.instance
        allow(::Resque).to receive(:queues) { ['default', 'high'] }
        allow(::Resque).to receive(:size).with('default') { 1 }
        allow(::Resque).to receive(:size).with('high') { 2 }

        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to eq 1
        expect(store.measurements[0].metric).to eq :qd
        expect(store.measurements[1].queue_name).to eq 'high'
        expect(store.measurements[1].value).to eq 2
        expect(store.measurements[1].metric).to eq :qd
      end

      it "always collects for the default queue" do
        expect(subject.enabled?).to be_truthy

        store = Store.instance
        allow(::Resque).to receive(:queues) { [] }
        allow(::Resque).to receive(:size) { 0 }

        subject.collect! store

        expect(store.measurements.size).to eq 1
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to eq 0
        expect(store.measurements[0].metric).to eq :qd
      end

      it "always collects for known queues" do
        expect(subject.enabled?).to be_truthy
        store = Store.instance

        allow(::Resque).to receive(:queues) { ['low'] }
        allow(::Resque).to receive(:size) { 0 }
        subject.collect! store

        Store.instance.instance_variable_set '@measurements', []
        allow(::Resque).to receive(:queues) { [] }
        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements.map(&:queue_name)).to eq %w[default low]
      end
    end
  end
end
