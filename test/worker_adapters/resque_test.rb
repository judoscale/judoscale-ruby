# frozen_string_literal: true

require "test_helper"
require "resque"
require "judoscale/worker_adapters/resque"
require "judoscale/metrics_store"

module Judoscale
  describe WorkerAdapters::Resque do
    subject { WorkerAdapters::Resque.instance }

    describe "#enabled?" do
      specify { _(subject).must_be :enabled? }
    end

    describe "#collect!" do
      let(:store) { MetricsStore.instance }

      after {
        subject.clear_queues
        store.clear
      }

      it "collects latency for each queue" do
        queues = ["default", "high"]
        sizes = {"default" => 1, "high" => 2}

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, ->(queue_name) { sizes.fetch(queue_name) }) {
            subject.collect! store
          }
        }

        _(store.metrics.size).must_equal 2
        _(store.metrics[0].queue_name).must_equal "default"
        _(store.metrics[0].value).must_equal 1
        _(store.metrics[0].identifier).must_equal :qd
        _(store.metrics[1].queue_name).must_equal "high"
        _(store.metrics[1].value).must_equal 2
        _(store.metrics[1].identifier).must_equal :qd
      end

      it "always collects for the default queue" do
        queues = []
        size = 0

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect! store
          }
        }

        _(store.metrics.size).must_equal 1
        _(store.metrics[0].queue_name).must_equal "default"
        _(store.metrics[0].value).must_equal 0
        _(store.metrics[0].identifier).must_equal :qd
      end

      it "always collects for known queues" do
        queues = ["low"]
        size = 0

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect! store
          }
        }

        store.clear
        queues = []

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect! store
          }
        }

        _(store.metrics.size).must_equal 2
        _(store.metrics.map(&:queue_name)).must_equal %w[default low]
      end

      it "logs debug information for each queue being collected" do
        use_config log_level: :debug do
          queues = ["default"]
          size = 2

          ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              subject.collect! store
            }
          }

          _(log_string).must_match %r{resque-qd.default=2}
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        queues = %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high]
        size = 2

        ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect! store
          }
        }

        _(store.metrics.size).must_equal 1
        _(store.metrics[0].queue_name).must_equal "default"
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        use_adapter_config :resque, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          queues = %W[low default high low-#{SecureRandom.uuid}]
          size = 2

          ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              subject.collect! store
            }
          }

          _(store.metrics.size).must_equal 2
          _(store.metrics[0].queue_name).must_equal "low"
          _(store.metrics[1].queue_name).must_be :start_with?, "low-"
        end
      end

      it "collects metrics only from the configured queues if the configuration is present, ignoring the queue filter" do
        use_adapter_config :resque, queues: %w[low ultra], queue_filter: ->(queue_name) { queue_name != "low" } do
          queues = %w[low default high]
          size = 2

          ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              subject.collect! store
            }
          }

          _(store.metrics.map(&:queue_name)).must_equal %w[low ultra]
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        use_adapter_config :resque, max_queues: 2 do
          queues = %w[low default high]
          size = 2

          ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              subject.collect! store
            }
          }

          _(store.metrics.map(&:queue_name)).must_equal %w[low high]
          _(log_string).must_match %r{Resque metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
