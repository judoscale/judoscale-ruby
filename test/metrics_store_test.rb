# frozen_string_literal: true

require "test_helper"
require "judoscale/metrics_store"

module Judoscale
  describe MetricsStore do
    let(:store) { MetricsStore.instance }

    after { store.clear }

    describe "#push" do
      it "keeps tracking of the pushed metrics internally in memory for reporting at a later time" do
        _(store.metrics).must_be :empty?

        store.push :qt, 1, Time.now

        _(store.metrics.size).must_equal 1
        _(store.metrics.first.identifier).must_equal :qt
      end

      it "stops tracking metrics after 2 minutes, assuming there was an issue with reporting, to avoid memory growing indefinitely" do
        store.push :qt, 1, Time.now
        _(store.metrics.size).must_equal 1

        Time.stub(:now, Time.now + 121) do
          store.push :qt, 1, Time.now
        end
        _(store.metrics.size).must_equal 1
      end
    end

    describe "#flush" do
      it "returns all metrics currently tracked by the store, clearing them in the process" do
        1.upto(3) { |i| store.push :qt, i, Time.now }
        _(store.metrics.size).must_equal 3

        flushed_metrics = store.flush
        _(flushed_metrics.size).must_equal 3
        _(store.metrics).must_be :empty?
      end

      it "tracks the last time metrics were flushed for reporting to allow continuously pushing metrics to the store" do
        flushed_at = store.flushed_at

        _(store.flush).must_be :empty?
        _(store.flushed_at).wont_equal flushed_at

        second_flushed_at = store.flushed_at
        store.push :qt, 1, Time.now

        _(store.flush.size).must_equal 1
        _(store.flushed_at).wont_equal second_flushed_at
      end
    end
  end
end
