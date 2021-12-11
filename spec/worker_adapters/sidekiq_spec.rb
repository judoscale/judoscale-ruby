# frozen_string_literal: true

require 'spec_helper'
require 'judoscale/worker_adapters/sidekiq'
require 'judoscale/store'

module Judoscale
  describe WorkerAdapters::Sidekiq do
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
        allow(::Sidekiq::Queue).to receive(:all) { [
          double(name: 'default', latency: 11, size: 1),
          double(name: 'high', latency: 22.222222, size: 2),
        ] }

        subject.collect! store

        expect(store.measurements.size).to eq 4
        expect(store.measurements[0].value).to eq 11000
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].metric).to eq :qt
        expect(store.measurements[1].value).to eq 1
        expect(store.measurements[1].queue_name).to eq 'default'
        expect(store.measurements[1].metric).to eq :qd
        expect(store.measurements[2].value).to eq 22223
        expect(store.measurements[2].queue_name).to eq 'high'
        expect(store.measurements[2].metric).to eq :qt
        expect(store.measurements[3].value).to eq 2
        expect(store.measurements[3].queue_name).to eq 'high'
        expect(store.measurements[3].metric).to eq :qd
      end

      it "always collects for the default queue" do
        expect(subject.enabled?).to be_truthy

        store = Store.instance
        allow(::Sidekiq::Queue).to receive(:all) { [] }
        allow_any_instance_of(::Sidekiq::Queue).to receive(:size) { 0 }
        allow_any_instance_of(::Sidekiq::Queue).to receive(:latency) { 0 }

        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to eq 0
        expect(store.measurements[0].metric).to eq :qt
        expect(store.measurements[1].queue_name).to eq 'default'
        expect(store.measurements[1].value).to eq 0
        expect(store.measurements[1].metric).to eq :qd
      end

      it "always collects for known queues" do
        expect(subject.enabled?).to be_truthy
        store = Store.instance

        allow(::Sidekiq::Queue).to receive(:all) { [ double(name: 'low', latency: 11, size: 1) ] }
        allow_any_instance_of(::Sidekiq::Queue).to receive(:size) { 0 }
        allow_any_instance_of(::Sidekiq::Queue).to receive(:latency) { 0 }
        subject.collect! store

        Store.instance.instance_variable_set '@measurements', []
        allow(::Sidekiq::Queue).to receive(:all) { [] }
        subject.collect! store

        expect(store.measurements.size).to eq 4
        expect(store.measurements.map(&:queue_name)).to eq %w[low low default default]
      end
    end
  end
end
