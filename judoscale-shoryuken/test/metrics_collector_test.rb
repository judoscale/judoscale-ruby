# frozen_string_literal: true

require "test_helper"
require "judoscale/shoryuken/metrics_collector"

module Judoscale
  ShoryukenQueueStub = Struct.new(:name, :latency, :size, keyword_init: true)

  describe Shoryuken::MetricsCollector do
    subject { Shoryuken::MetricsCollector.new }

    def stub_sqs(queue_depths)
      # Given a queue name, Shoryuken will fetch the queue URL first, then use that to
      # request the queue attributes. These stubs translate to those individual calls.
      ::Shoryuken.sqs_client.tap { |sqs|
        sqs.stub_responses(:get_queue_url, ->(context) {
          {queue_url: "https://sqs.us-east-1.amazonaws.com/12345/#{context.params[:queue_name]}"}
        })
        sqs.stub_responses(:get_queue_attributes, ->(context) {
          depth = queue_depths.fetch(context.params[:queue_url].split("/").last)
          {attributes: {"ApproximateNumberOfMessages" => depth.to_s}}
        })
      }
    end

    describe "#collect" do
      after {
        subject.clear_queues
      }

      it "collects queue depth for each queue (latency is not available yet)" do
        stub_sqs "default" => 10, "high" => 5

        metrics = ::Shoryuken.stub(:ungrouped_queues, %w[default high]) {
          subject.collect
        }

        _(metrics.size).must_equal 2
        _(metrics[0].value).must_equal 10
        _(metrics[0].queue_name).must_equal "default"
        _(metrics[0].identifier).must_equal :qd
        _(metrics[1].value).must_equal 5
        _(metrics[1].queue_name).must_equal "high"
        _(metrics[1].identifier).must_equal :qd
      end

      it "always collects for known queues" do
        stub_sqs "default" => 0, "high" => 1

        metrics = ::Shoryuken.stub(:ungrouped_queues, []) {
          subject.collect
        }

        _(metrics).must_be :empty?

        metrics = ::Shoryuken.stub(:ungrouped_queues, %w[default]) {
          subject.collect
        }

        _(metrics.size).must_equal 1
        _(metrics.map(&:queue_name)).must_equal %w[default]

        metrics = ::Shoryuken.stub(:ungrouped_queues, %w[high]) {
          subject.collect
        }

        _(metrics.size).must_equal 2
        _(metrics.map(&:queue_name)).must_equal %w[default high]
      end

      it "logs debug information for each queue being collected" do
        use_config log_level: :debug do
          stub_sqs "default" => 10

          ::Shoryuken.stub(:ungrouped_queues, %w[default]) {
            subject.collect
          }

          _(log_string).must_match %r{shoryuken-qd.default=10}
          _(log_string).wont_match %r{shoryuken-qt}
          _(log_string).wont_match %r{shoryuken-busy}
        end
      end

      it "filters queues matching UUID format by default, to prevent reporting for dynamically generated queues" do
        queues = %W[low-#{SecureRandom.uuid} default #{SecureRandom.uuid}-high]
        stub_sqs queues.map.with_index.to_h

        metrics = ::Shoryuken.stub(:ungrouped_queues, queues) {
          subject.collect
        }

        _(metrics.size).must_equal 1
        _(metrics.map(&:queue_name)).must_equal %w[default]
      end

      it "filters queues to collect metrics from based on the configured queue filter proc, overriding the default UUID filter" do
        use_adapter_config :shoryuken, queue_filter: ->(queue_name) { queue_name.start_with? "low" } do
          queues = %W[low default high low-#{SecureRandom.uuid}]
          stub_sqs queues.map.with_index.to_h

          metrics = ::Shoryuken.stub(:ungrouped_queues, queues) {
            subject.collect
          }

          _(metrics.size).must_equal 2
          _(metrics[0].queue_name).must_equal "low"
          _(metrics[1].queue_name).must_be :start_with?, "low-"
        end
      end

      it "collects metrics only from the configured queues if the configuration is present, ignoring the queue filter" do
        use_adapter_config :shoryuken, queues: %w[low ultra], queue_filter: ->(queue_name) { queue_name != "low" } do
          queues = %w[low default high]
          stub_sqs "low" => 5, "ultra" => 10

          metrics = ::Shoryuken.stub(:ungrouped_queues, queues) {
            subject.collect
          }

          _(metrics.map(&:queue_name)).must_equal %w[low ultra]
        end
      end

      it "collects metrics up to the configured number of max queues, sorting by length of the queue name" do
        use_adapter_config :shoryuken, max_queues: 2 do
          queues = %w[low default high]
          stub_sqs queues.map.with_index.to_h

          metrics = ::Shoryuken.stub(:ungrouped_queues, queues) {
            subject.collect
          }

          _(metrics.map(&:queue_name)).must_equal %w[low high]
          _(log_string).must_match %r{Shoryuken metrics reporting only 2 queues max, skipping the rest \(1\)}
        end
      end
    end
  end
end
