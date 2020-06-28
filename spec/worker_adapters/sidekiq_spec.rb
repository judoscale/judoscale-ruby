# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/worker_adapters/sidekiq'
require 'rails_autoscale_agent/store'

module RailsAutoscaleAgent
  describe WorkerAdapters::Sidekiq do
    subject { described_class.instance }

    describe "#enabled?" do
      specify { expect(subject.enabled?).to be_truthy }
    end

    describe "#collect!" do
      after { Store.instance.instance_variable_set '@measurements', [] }

      it "collects latency for each queue" do
        expect(subject.enabled?).to be_truthy

        store = Store.instance
        allow(::Sidekiq::Queue).to receive(:all) { [
          double(name: 'low', latency: 11, size: 1),
          double(name: 'high', latency: 22.222222, size: 2),
        ] }

        subject.collect! store

        expect(store.measurements.size).to eq 4
        expect(store.measurements[0].value).to eq 11000
        expect(store.measurements[0].queue_name).to eq 'low'
        expect(store.measurements[0].metric).to eq :qt
        expect(store.measurements[1].value).to eq 1
        expect(store.measurements[1].queue_name).to eq 'low'
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

        subject.collect! store

        expect(store.measurements.size).to eq 2
        expect(store.measurements[0].queue_name).to eq 'default'
        expect(store.measurements[0].value).to eq 0
        expect(store.measurements[0].metric).to eq :qt
        expect(store.measurements[1].queue_name).to eq 'default'
        expect(store.measurements[1].value).to eq 0
        expect(store.measurements[1].metric).to eq :qd
      end
    end
  end
end
