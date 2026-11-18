# frozen_string_literal: true

require "test_helper"
require "judoscale/sidekiq/metrics_collector"

module Judoscale
  SidekiqQueueStub = Struct.new(:name, :latency, :size, keyword_init: true)

  describe Sidekiq::MetricsCollector do
    subject { Sidekiq::MetricsCollector.new }

    # Busy jobs are tracked by default; tests that cover busy jobs turn it back on.
    before { Judoscale::Config.instance.sidekiq.track_busy_jobs = false }

    describe "#collect" do
      after {
        subject.clear_queues
      }

      it "collects latency for each queue" do
        queues = [
          SidekiqQueueStub.new(name: "default", latency: 11, size: 1),
          SidekiqQueueStub.new(name: "high", latency: 22.222222, size: 2)
        ]

        metrics = ::Sidekiq::Queue.stub(:all, queues) {
          subject.collect
        }

        _(metrics.size).must_equal 4
        _(metrics[0].value).must_equal 11000
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].identifier).must_equal :qt
        _(metrics[1].value).must_equal 1
        _(metrics[1].queue_name).must_equal "default"
        _(metrics[1].identifier).must_equal :qd
        _(metrics[2].value).must_equal 22223
        _(metrics[2].queue_name).must_equal "high"
        _(metrics[2].identifier).must_equal :qt
        _(metrics[3].value).must_equal 2
        _(metrics[3].queue_name).must_equal "high"
        _(metrics[3].identifier).must_equal :qd
      end

      it "always collects for known queues" do
        queues = []

        metrics = ::Sidekiq::Queue.stub(:all, queues) {
          subject.collect
        }

        _(metrics).must_be :empty?

        queues = [SidekiqQueueStub.new(name: "default", latency: 11, size: 1)]

        metrics = ::Sidekiq::Queue.stub(:all, queues) {
          subject.collect
        }

        _(metrics.size).must_equal 2
        _(metrics.map(&:queue_name)).must_equal %w[default default]

        queues = []
        queue_default = SidekiqQueueStub.new(name: "default", latency: 0, size: 0)
        new_queues = {"default" => queue_default}

        metrics = ::Sidekiq::Queue.stub(:all, queues) {
          ::Sidekiq::Queue.stub(:new, ->(queue_name) { new_queues.fetch(queue_name) }) {
            subject.collect
          }
        }

        _(metrics.size).must_equal 2
        _(metrics.map(&:queue_name)).must_equal %w[default default]
      end

      it "logs debug information for each queue being collected" do
        use_config log_level: :debug do
          queues = [SidekiqQueueStub.new(name: "default", latency: 11, size: 1)]

          ::Sidekiq::Queue.stub(:all, queues) {
            subject.collect
          }

          _(log_string).must_match %r{sidekiq-qt.default=11000ms sidekiq-qd.default=1}
          _(log_string).wont_match %r{sidekiq-busy}
        end
      end

      it "tracks busy jobs when the configuration is enabled" do
        use_adapter_config :sidekiq, track_busy_jobs: true do
          now = Time.at(Time.now.to_i)
          queues = [
            SidekiqQueueStub.new(name: "default", latency: 11, size: 1),
            SidekiqQueueStub.new(name: "high", latency: 22.222222, size: 2),
            SidekiqQueueStub.new(name: "low", latency: 0, size: 0)
          ]
          high_work = {"queue" => "high", "run_at" => now.to_i - 5, "payload" => '{"queue":"high"}'}
          # Sidekiq 7.2+ yields Sidekiq::Work objects instead of hashes
          high_work = ::Sidekiq::Work.new("pid1", "tid3", high_work) if defined?(::Sidekiq::Work)
          workers = [
            ["pid1", "tid1", {"run_at" => now.to_i - 10, "payload" => {"queue" => "default"}}],
            ["pid1", "tid2", {"run_at" => now.to_i - 30, "payload" => {"queue" => "default"}}],
            ["pid1", "tid3", high_work]
          ]

          metrics = freeze_time(now) {
            ::Sidekiq::Workers.stub(:new, workers) {
              ::Sidekiq::Queue.stub(:all, queues) {
                subject.collect
              }
            }
          }

          metrics = metrics.to_h { |metric| [[metric.queue_name, metric.identifier], metric.value] }
          _(metrics.size).must_equal 12
          _(metrics[["default", :busy]]).must_equal 2
          _(metrics[["default", :bt]]).must_equal 30_000
          _(metrics[["high", :busy]]).must_equal 1
          _(metrics[["high", :bt]]).must_equal 5_000
          _(metrics[["low", :busy]]).must_equal 0
          _(metrics[["low", :bt]]).must_equal 0
        end
      end

      it "gracefully handles when the Workers payload is a string" do
        use_adapter_config :sidekiq, track_busy_jobs: true do
          queues = [
            SidekiqQueueStub.new(name: "default", latency: 11, size: 1)
          ]
          workers = [
            # The payload appears to be a JSON string in Sidekiq 7
            ["pid1", "tid1", {"run_at" => Time.now.to_i, "payload" => '{"queue":"default"}'}]
          ]

          metrics = ::Sidekiq::Workers.stub(:new, workers) {
            ::Sidekiq::Queue.stub(:all, queues) {
              subject.collect
            }
          }

          _(metrics.size).must_equal 4
          _(metrics[2].value).must_equal 1
          _(metrics[2].queue_name).must_equal "default"
          _(metrics[2].identifier).must_equal :busy
        end
      end

      it "logs debug information about busy jobs being collected" do
        use_config log_level: :debug do
          use_adapter_config :sidekiq, track_busy_jobs: true do
            queues = [SidekiqQueueStub.new(name: "default", latency: 11, size: 1)]
            workers = [["pid1", "tid1", {"run_at" => Time.now.to_i - 2, "payload" => {"queue" => "default"}}]]

            ::Sidekiq::Workers.stub(:new, workers) {
              ::Sidekiq::Queue.stub(:all, queues) {
                subject.collect
              }
            }

            _(log_string).must_match %r{sidekiq-qt.default=.+ sidekiq-qd.default=.+ sidekiq-busy.default=1 sidekiq-bt.default=\d+ms}
          end
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        queues = %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high].map { |name|
          SidekiqQueueStub.new(name: name, latency: 5, size: 1)
        }

        metrics = ::Sidekiq::Queue.stub(:all, queues) {
          subject.collect
        }

        _(metrics.size).must_equal 2
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[1].queue_name).must_equal "default"
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        use_adapter_config :sidekiq, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          queues = %W[low default high low-#{SecureRandom.uuid}].map { |name|
            SidekiqQueueStub.new(name: name, latency: 5, size: 1)
          }

          metrics = ::Sidekiq::Queue.stub(:all, queues) {
            subject.collect
          }

          _(metrics.size).must_equal 4
          _(metrics[0].queue_name).must_equal "low"
          _(metrics[1].queue_name).must_equal "low"
          _(metrics[2].queue_name).must_be :start_with?, "low-"
          _(metrics[3].queue_name).must_be :start_with?, "low-"
        end
      end

      it "collects metrics only from the configured queues if the configuration is present, ignoring the queue filter" do
        use_adapter_config :sidekiq, queues: %w[low ultra], queue_filter: ->(queue_name) { queue_name != "low" } do
          queues = %w[low default high].map { |name| SidekiqQueueStub.new(name: name, latency: 5, size: 1) }
          new_queues = {"ultra" => SidekiqQueueStub.new(name: "ultra", latency: 0, size: 0)}

          metrics = ::Sidekiq::Queue.stub(:all, queues) {
            ::Sidekiq::Queue.stub(:new, ->(queue_name) { new_queues.fetch(queue_name) }) {
              subject.collect
            }
          }

          _(metrics.map(&:queue_name)).must_equal %w[low low ultra ultra]
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        use_adapter_config :sidekiq, max_queues: 2 do
          queues = %w[low default high].map { |name| SidekiqQueueStub.new(name: name, latency: 1, size: 1) }

          metrics = ::Sidekiq::Queue.stub(:all, queues) {
            subject.collect
          }

          _(metrics.map(&:queue_name)).must_equal %w[low low high high]
          _(log_string).must_match %r{Sidekiq metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
