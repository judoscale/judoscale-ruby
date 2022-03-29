# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-ruby"

require "minitest/autorun"
require "minitest/spec"
require "webmock/minitest"

require "active_record"
require "delayed_job"
require "delayed_job_active_record"

ActiveRecord::Base.establish_connection(adapter: "sqlite3", database: ":memory:")

ActiveRecord::Schema.define do
  # https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/generators/delayed_job/templates/migration.rb#L3
  # standard:disable all
  create_table :delayed_jobs do |table|
    table.integer :priority, default: 0, null: false # Allows some jobs to jump to the front of the queue
    table.integer :attempts, default: 0, null: false # Provides for retries, but still fail eventually.
    table.text :handler,                 null: false # YAML-encoded string of the object that will do work
    table.text :last_error                           # reason for last failure (See Note below)
    table.datetime :run_at                           # When to run. Could be Time.zone.now for immediately, or sometime in the future.
    table.datetime :locked_at                        # Set when a client is working on this object
    table.datetime :failed_at                        # Set when all retries have failed (actually, by default, the record is deleted instead)
    table.string :locked_by                          # Who is working on this object (if locked)
    table.string :queue                              # The name of the queue this job is in
    table.timestamps null: true
  end

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
