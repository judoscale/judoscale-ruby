# frozen_string_literal: true

require "test_helper"
require "judoscale/worker_adapters/sidekiq"
require "judoscale/store"

module Judoscale
  SidekiqQueueStub = Struct.new(:name, :latency, :size, keyword_init: true)

  describe WorkerAdapters::Sidekiq do
    subject { WorkerAdapters::Sidekiq.instance }

    describe "#enabled?" do
      specify { _(subject).must_be :enabled? }
    end

    describe "#collect!" do
      let(:store) { Store.instance }

      after {
        subject.clear_queues
        store.clear
      }

      it "collects latency for each queue" do
        _(subject).must_be :enabled?

        queues = [
          SidekiqQueueStub.new(name: "default", latency: 11, size: 1),
          SidekiqQueueStub.new(name: "high", latency: 22.222222, size: 2)
        ]

        ::Sidekiq::Queue.stub(:all, queues) {
          subject.collect! store
        }

        _(store.measurements.size).must_equal 4
        _(store.measurements[0].value).must_equal 11000
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].metric).must_equal :qt
        _(store.measurements[1].value).must_equal 1
        _(store.measurements[1].queue_name).must_equal "default"
        _(store.measurements[1].metric).must_equal :qd
        _(store.measurements[2].value).must_equal 22223
        _(store.measurements[2].queue_name).must_equal "high"
        _(store.measurements[2].metric).must_equal :qt
        _(store.measurements[3].value).must_equal 2
        _(store.measurements[3].queue_name).must_equal "high"
        _(store.measurements[3].metric).must_equal :qd
      end

      it "always collects for the default queue" do
        _(subject).must_be :enabled?

        queues = []
        queue_default = SidekiqQueueStub.new(name: "default", latency: 0, size: 0)

        ::Sidekiq::Queue.stub(:all, queues) {
          ::Sidekiq::Queue.stub(:new, queue_default) {
            subject.collect! store
          }
        }

        _(store.measurements.size).must_equal 2
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[0].value).must_equal 0
        _(store.measurements[0].metric).must_equal :qt
        _(store.measurements[1].queue_name).must_equal "default"
        _(store.measurements[1].value).must_equal 0
        _(store.measurements[1].metric).must_equal :qd
      end

      it "always collects for known queues" do
        _(subject).must_be :enabled?

        queues = [SidekiqQueueStub.new(name: "low", latency: 11, size: 1)]
        queue_default = SidekiqQueueStub.new(name: "default", latency: 0, size: 0)

        ::Sidekiq::Queue.stub(:all, queues) {
          ::Sidekiq::Queue.stub(:new, queue_default) {
            subject.collect! store
          }
        }

        store.clear
        queues = []
        queue_low = SidekiqQueueStub.new(name: "low", latency: 0, size: 0)
        new_queues = {"low" => queue_low, "default" => queue_default}

        ::Sidekiq::Queue.stub(:all, queues) {
          ::Sidekiq::Queue.stub(:new, ->(queue_name) { new_queues.fetch(queue_name) }) {
            subject.collect! store
          }
        }

        _(store.measurements.size).must_equal 4
        _(store.measurements.map(&:queue_name)).must_equal %w[default default low low]
      end

      it "logs debug information for each queue being collected" do
        _(subject).must_be :enabled?

        use_config debug: true do
          queues = [SidekiqQueueStub.new(name: "default", latency: 11, size: 1)]

          ::Sidekiq::Queue.stub(:all, queues) {
            subject.collect! store
          }

          _(log_string).must_match %r{sidekiq-qt.default=11000ms sidekiq-qd.default=1}
          _(log_string).wont_match %r{sidekiq-busy}
        end
      end

      it "tracks long running jobs when the configuration is enabled" do
        _(subject).must_be :enabled?

        use_adapter_config :sidekiq, track_long_running_jobs: true do
          queues = [
            SidekiqQueueStub.new(name: "default", latency: 11, size: 1),
            SidekiqQueueStub.new(name: "high", latency: 22.222222, size: 2)
          ]
          workers = [
            ["pid1", "tid1", {"payload" => {"queue" => "default"}}],
            ["pid1", "tid2", {"payload" => {"queue" => "default"}}],
            ["pid1", "tid3", {"payload" => {"queue" => "high"}}]
          ]

          ::Sidekiq::Workers.stub(:new, workers) {
            ::Sidekiq::Queue.stub(:all, queues) {
              subject.collect! store
            }
          }

          _(store.measurements.size).must_equal 6
          _(store.measurements[2].value).must_equal 2
          _(store.measurements[2].queue_name).must_equal "default"
          _(store.measurements[2].metric).must_equal :busy
          _(store.measurements[5].value).must_equal 1
          _(store.measurements[5].queue_name).must_equal "high"
          _(store.measurements[5].metric).must_equal :busy
        end
      end

      it "logs debug information about long running jobs being collected" do
        _(subject).must_be :enabled?

        use_config debug: true do
          use_adapter_config :sidekiq, track_long_running_jobs: true do
            queues = [SidekiqQueueStub.new(name: "default", latency: 11, size: 1)]
            workers = [["pid1", "tid1", {"payload" => {"queue" => "default"}}]]

            ::Sidekiq::Workers.stub(:new, workers) {
              ::Sidekiq::Queue.stub(:all, queues) {
                subject.collect! store
              }
            }

            _(log_string).must_match %r{sidekiq-qt.default=.+ sidekiq-qd.default=.+ sidekiq-busy.default=1}
          end
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        _(subject).must_be :enabled?

        queues = %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high].map { |name|
          SidekiqQueueStub.new(name: name, latency: 5, size: 1)
        }

        ::Sidekiq::Queue.stub(:all, queues) {
          subject.collect! store
        }

        _(store.measurements.size).must_equal 2
        _(store.measurements[0].queue_name).must_equal "default"
        _(store.measurements[1].queue_name).must_equal "default"
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        _(subject).must_be :enabled?

        use_adapter_config :sidekiq, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          queues = %W[low default high low-#{SecureRandom.uuid}].map { |name|
            SidekiqQueueStub.new(name: name, latency: 5, size: 1)
          }

          ::Sidekiq::Queue.stub(:all, queues) {
            subject.collect! store
          }

          _(store.measurements.size).must_equal 4
          _(store.measurements[0].queue_name).must_equal "low"
          _(store.measurements[1].queue_name).must_equal "low"
          _(store.measurements[2].queue_name).must_be :start_with?, "low-"
          _(store.measurements[3].queue_name).must_be :start_with?, "low-"
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        _(subject).must_be :enabled?

        use_adapter_config :sidekiq, max_queues: 2 do
          queues = %w[low default high].map { |name| SidekiqQueueStub.new(name: name, latency: 1, size: 1) }

          ::Sidekiq::Queue.stub(:all, queues) {
            subject.collect! store
          }

          _(store.measurements.size).must_equal 4
          _(store.measurements[0].queue_name).must_equal "low"
          _(store.measurements[1].queue_name).must_equal "low"
          _(store.measurements[2].queue_name).must_equal "high"
          _(store.measurements[3].queue_name).must_equal "high"
          _(log_string).must_match %r{Sidekiq metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
