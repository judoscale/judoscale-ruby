# frozen_string_literal: true

require "test_helper"
require "judoscale/resque/metrics_collector"
require "securerandom"

module Judoscale
  describe Resque::MetricsCollector do
    subject { Resque::MetricsCollector.new }

    describe "#collect" do
      after {
        subject.clear_queues
      }

      it "collects latency for each queue" do
        queues = ["default", "high"]
        sizes = {"default" => 1, "high" => 2}

        metrics = ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, ->(queue_name) { sizes.fetch(queue_name) }) {
            subject.collect
          }
        }

        _(metrics.size).must_equal 2
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].value).must_equal 1
        _(metrics[0].identifier).must_equal :qd
        _(metrics[1].queue_name).must_equal "high"
        _(metrics[1].value).must_equal 2
        _(metrics[1].identifier).must_equal :qd
      end

      it "always collects for known queues" do
        queues = []

        metrics = ::Resque.stub(:queues, queues) {
          subject.collect
        }

        _(metrics).must_be :empty?

        queues = ["default"]
        size = 0

        metrics = ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect
          }
        }

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"

        queues = []

        metrics = ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect
          }
        }

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
      end

      it "logs debug information for each queue being collected" do
        use_config log_level: :debug do
          queues = ["default"]
          size = 2

          ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              subject.collect
            }
          }

          _(log_string).must_match %r{resque-qd.default=2}
          _(log_string).wont_match %r{resque-busy}
        end
      end

      it "tracks busy jobs when the configuration is enabled, ignoring idle workers" do
        use_adapter_config :resque, track_busy_jobs: true do
          queues = ["default", "high"]
          size = 2
          workers = [
            ::Resque::Worker.new("default", "a-queue").tap { |worker| worker.working_on ::Resque::Job.new("default", nil) },
            ::Resque::Worker.new("default", "b-queue").tap { |worker| worker.working_on ::Resque::Job.new("default", nil) },
            ::Resque::Worker.new("high", "a-queue").tap { |worker| worker.working_on ::Resque::Job.new("high", nil) },
            ::Resque::Worker.new("high", "b-queue") # idle, shouldn't be tracked
          ]

          metrics = ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              ::Resque.stub(:working, workers) {
                subject.collect
              }
            }
          }

          _(metrics.size).must_equal 4
          _(metrics[1].value).must_equal 2
          _(metrics[1].queue_name).must_equal "default"
          _(metrics[1].identifier).must_equal :busy
          _(metrics[3].value).must_equal 1
          _(metrics[3].queue_name).must_equal "high"
          _(metrics[3].identifier).must_equal :busy
        end
      end

      it "logs debug information about busy jobs being collected" do
        use_config log_level: :debug do
          use_adapter_config :resque, track_busy_jobs: true do
            queues = ["default"]
            size = 2
            workers = [::Resque::Worker.new(*queues).tap { |worker| worker.working_on ::Resque::Job.new("default", nil) }]

            ::Resque.stub(:queues, queues) {
              ::Resque.stub(:size, size) {
                ::Resque.stub(:working, workers) {
                  subject.collect
                }
              }
            }

            _(log_string).must_match %r{resque-qd.default=2 resque-busy.default=1}
          end
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        queues = %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high]
        size = 2

        metrics = ::Resque.stub(:queues, queues) {
          ::Resque.stub(:size, size) {
            subject.collect
          }
        }

        _(metrics.size).must_equal 1
        _(metrics[0].queue_name).must_equal "default"
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        use_adapter_config :resque, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          queues = %W[low default high low-#{SecureRandom.uuid}]
          size = 2

          metrics = ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              subject.collect
            }
          }

          _(metrics.size).must_equal 2
          _(metrics[0].queue_name).must_equal "low"
          _(metrics[1].queue_name).must_be :start_with?, "low-"
        end
      end

      it "collects metrics only from the configured queues if the configuration is present, ignoring the queue filter" do
        use_adapter_config :resque, queues: %w[low ultra], queue_filter: ->(queue_name) { queue_name != "low" } do
          queues = %w[low default high]
          size = 2

          metrics = ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              subject.collect
            }
          }

          _(metrics.map(&:queue_name)).must_equal %w[low ultra]
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        use_adapter_config :resque, max_queues: 2 do
          queues = %w[low default high]
          size = 2

          metrics = ::Resque.stub(:queues, queues) {
            ::Resque.stub(:size, size) {
              subject.collect
            }
          }

          _(metrics.map(&:queue_name)).must_equal %w[low high]
          _(log_string).must_match %r{Resque metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
