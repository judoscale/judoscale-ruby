# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-ruby"

require "minitest/autorun"
require "minitest/spec"
require "webmock/minitest"

require "active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  # standard:disable all
  create_table "que_jobs" do |t|
    t.integer "priority", limit: 2, default: 100, null: false
    t.datetime "run_at", null: false
    t.integer "error_count", default: 0, null: false
    t.text "queue", default: "default", null: false
    t.datetime "finished_at"
    t.datetime "expired_at"
  end
   # standard:enable all
end

require "judoscale/job_metrics_collector"
require "judoscale/web_metrics_collector"

module Judoscale
  module Test
    class TestJobMetricsCollector < Judoscale::JobMetricsCollector
      def self.adapter_identifier
        :test_job_config
      end

      def collect
        []
      end
    end

    class TestWebMetricsCollector < Judoscale::WebMetricsCollector
      def collect
        [Metric.new(:qt, 1, Time.now)]
      end
    end
  end

  add_adapter :test_web, {}, metrics_collector: Test::TestWebMetricsCollector
  add_adapter :test_job, {}, metrics_collector: Test::TestJobMetricsCollector
  Config.add_adapter_config :test_job_config, Config::JobAdapterConfig
end

Dir[File.expand_path("./support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(Judoscale::Test)
