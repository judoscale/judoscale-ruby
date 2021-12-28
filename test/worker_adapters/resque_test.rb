# frozen_string_literal: true

require "test_helper"
require "judoscale/worker_adapters/resque"
require "judoscale/store"

module Judoscale
  describe WorkerAdapters::Resque do
    subject { WorkerAdapters::Resque.instance }

    describe "#enabled?" do
      specify { _(subject).must_be :enabled? }
    end

    describe "#collect!" do
      before { subject.queues = nil }
      after { Store.instance.instance_variable_set "@measurements", [] }

      it "collects latency for each queue" do
        _(subject).must_be :enabled?

        store = Store.instance
        queues = ["default", "high"]
        sizes = {"default" => 1, "high" => 2}

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, ->(queue_name) { sizes.fetch(queue_name) }) {
            subject.collect! store
          }
        }

        _(store.measurements.size).must_equal 2
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_equal 1
        _(store.measurements[0].metric).must_equal :qd
        _(store.measurements[1].queue_name).must_equal "high"
        _(store.measurements[1].value).must_equal 2
        _(store.measurements[1].metric).must_equal :qd
      end

      it "always collects for the default queue" do
        _(subject).must_be :enabled?

        store = Store.instance
        queues = []
        size = 0

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect! store
          }
        }

        _(store.measurements.size).must_equal 1
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_equal 0
        _(store.measurements[0].metric).must_equal :qd
      end

      it "always collects for known queues" do
        _(subject).must_be :enabled?
        store = Store.instance

        queues = ["low"]
        size = 0

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect! store
          }
        }

        Store.instance.instance_variable_set "@measurements", []
        queues = []

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect! store
          }
        }

        _(store.measurements.size).must_equal 2
        _(store.measurements.map(&:queue_name)).must_equal %w[default low]
      end
    end
  end
end
