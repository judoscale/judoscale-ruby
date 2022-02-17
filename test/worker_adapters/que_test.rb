# frozen_string_literal: true

require "test_helper"
require "que"
require "judoscale/worker_adapters/que"
require "judoscale/store"

module Judoscale
  describe WorkerAdapters::Que do
    def enqueue(queue, run_at)
      ActiveRecord::Base.connection.insert <<~SQL
        INSERT INTO que_jobs (queue, run_at)
        VALUES ('#{queue}', '#{run_at.iso8601(6)}')
      SQL
    end

    subject { WorkerAdapters::Que.instance }

    describe "#enabled?" do
      specify { _(subject).must_be :enabled? }
    end

    describe "#collect!" do
      let(:store) { Store.instance }

      after {
        ActiveRecord::Base.connection.execute("DELETE FROM que_jobs")
        subject.clear_queues
        store.clear
      }

      it "collects latency for each queue" do
        enqueue("default", Time.now - 11)
        enqueue("high", Time.now - 22.2222)

        subject.collect! store

        _(store.measurements.size).must_equal 2
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_be_within_delta 11000, 5
        _(store.measurements[0].metric).must_equal :qt
        _(store.measurements[1].queue_name).must_equal "high"
        _(store.measurements[1].value).must_be_within_delta 22222, 5
        _(store.measurements[1].metric).must_equal :qt
      end

      it "logs debug information for each queue being collected" do
        use_config log_level: :debug do
          enqueue("default", Time.now)

          subject.collect! store

          _(log_string).must_match %r{que-qt.default=\d+ms}
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high].each { |queue| enqueue(queue, Time.now) }

        subject.collect! store

        _(store.measurements.size).must_equal 1
        _(store.measurements[0].queue_name).must_equal "default"
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        use_adapter_config :que, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          %W[low default high low-#{SecureRandom.uuid}].each { |queue| enqueue(queue, Time.now) }

          subject.collect! store

          _(store.measurements.size).must_equal 2
          _(store.measurements[0].queue_name).must_equal "low"
          _(store.measurements[1].queue_name).must_be :start_with?, "low-"
        end
      end

      it "collects metrics only from the configured queues if the configuration is present, ignoring the queue filter" do
        use_adapter_config :que, queues: %w[low ultra], queue_filter: ->(queue_name) { queue_name != "low" } do
          %w[low default high].each { |queue| enqueue(queue, Time.now) }

          subject.collect! store

          _(store.measurements.map(&:queue_name)).must_equal %w[low ultra]
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        use_adapter_config :que, max_queues: 2 do
          %w[low default high].each { |queue| enqueue(queue, Time.now) }

          subject.collect! store

          _(store.measurements.map(&:queue_name)).must_equal %w[low high]
          _(log_string).must_match %r{Que metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
