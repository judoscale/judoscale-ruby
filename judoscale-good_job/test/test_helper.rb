# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-good_job"

require "minitest/autorun"
require "minitest/spec"

ENV["RACK_ENV"] ||= "test"
require "action_controller"

class TestRailsApp < Rails::Application
  config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
  config.secret_key_base = "test-secret"
  config.eager_load = false
  config.logger = ::Logger.new(StringIO.new, progname: "rails-app")
  config.active_job.queue_adapter = :good_job
  # Don't execute the jobs in-process. Our specs need to assert that jobs are in the queue.
  config.good_job.execution_mode = :external
  routes.append do
    root to: proc {
      [200, {"Content-Type" => "text/plain"}, ["Hello World"]]
    }
  end
  initialize!
end

require "active_record"

DATABASE_NAME = "judoscale_good_job_test"
DATABASE_USERNAME = "postgres"
DATABASE_URL = "postgres://#{DATABASE_USERNAME}:@localhost/#{DATABASE_NAME}"

ActiveRecord::Tasks::DatabaseTasks.create(DATABASE_URL)
Minitest.after_run {
  ActiveRecord::Tasks::DatabaseTasks.drop(DATABASE_URL)
}
ActiveRecord::Base.establish_connection(DATABASE_URL)

ActiveRecord::Schema.define do
  # https://github.com/bensheldon/good_job/blob/main/lib/generators/good_job/templates/install/migrations/create_good_jobs.rb.erb#L8
  # standard:disable all
  suppress_messages do
    create_table :good_jobs, id: :uuid do |t|
      t.text :queue_name
      t.integer :priority
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :performed_at
      t.datetime :finished_at
      t.text :error

      t.timestamps

      t.uuid :active_job_id
      t.text :concurrency_key
      t.text :cron_key
      t.uuid :retried_good_job_id
      t.datetime :cron_at

      t.uuid :batch_id
      t.uuid :batch_callback_id

      t.boolean :is_discrete
      t.integer :executions_count
      t.text :job_class
      t.integer :error_event, limit: 2
      t.text :labels, array: true
      t.uuid :locked_by_id
      t.datetime :locked_at
    end

    create_table :good_job_batches, id: :uuid do |t|
      t.timestamps
      t.text :description
      t.jsonb :serialized_properties
      t.text :on_finish
      t.text :on_success
      t.text :on_discard
      t.text :callback_queue_name
      t.integer :callback_priority
      t.datetime :enqueued_at
      t.datetime :discarded_at
      t.datetime :finished_at
    end

    create_table :good_job_executions, id: :uuid do |t|
      t.timestamps

      t.uuid :active_job_id, null: false
      t.text :job_class
      t.text :queue_name
      t.jsonb :serialized_params
      t.datetime :scheduled_at
      t.datetime :finished_at
      t.text :error
      t.integer :error_event, limit: 2
      t.text :error_backtrace, array: true
      t.uuid :process_id
      t.interval :duration
    end

    create_table :good_job_processes, id: :uuid do |t|
      t.timestamps
      t.jsonb :state
      t.integer :lock_type, limit: 2
    end

    create_table :good_job_settings, id: :uuid do |t|
      t.timestamps
      t.text :key
      t.jsonb :value
      t.index :key, unique: true
    end

    add_index :good_jobs, :scheduled_at, where: "(finished_at IS NULL)", name: :index_good_jobs_on_scheduled_at
    add_index :good_jobs, [:queue_name, :scheduled_at], where: "(finished_at IS NULL)", name: :index_good_jobs_on_queue_name_and_scheduled_at
    add_index :good_jobs, [:active_job_id, :created_at], name: :index_good_jobs_on_active_job_id_and_created_at
    add_index :good_jobs, :concurrency_key, where: "(finished_at IS NULL)", name: :index_good_jobs_on_concurrency_key_when_unfinished
    add_index :good_jobs, [:cron_key, :created_at], where: "(cron_key IS NOT NULL)", name: :index_good_jobs_on_cron_key_and_created_at_cond
    add_index :good_jobs, [:cron_key, :cron_at], where: "(cron_key IS NOT NULL)", unique: true, name: :index_good_jobs_on_cron_key_and_cron_at_cond
    add_index :good_jobs, [:finished_at], where: "retried_good_job_id IS NULL AND finished_at IS NOT NULL", name: :index_good_jobs_jobs_on_finished_at
    add_index :good_jobs, [:priority, :created_at], order: { priority: "DESC NULLS LAST", created_at: :asc },
      where: "finished_at IS NULL", name: :index_good_jobs_jobs_on_priority_created_at_when_unfinished
    add_index :good_jobs, [:priority, :created_at], order: { priority: "ASC NULLS LAST", created_at: :asc },
      where: "finished_at IS NULL", name: :index_good_job_jobs_for_candidate_lookup
    add_index :good_jobs, [:batch_id], where: "batch_id IS NOT NULL"
    add_index :good_jobs, [:batch_callback_id], where: "batch_callback_id IS NOT NULL"
    add_index :good_jobs, :labels, using: :gin, where: "(labels IS NOT NULL)", name: :index_good_jobs_on_labels

    add_index :good_job_executions, [:active_job_id, :created_at], name: :index_good_job_executions_on_active_job_id_and_created_at
    add_index :good_jobs, [:priority, :scheduled_at], order: { priority: "ASC NULLS LAST", scheduled_at: :asc },
      where: "finished_at IS NULL AND locked_by_id IS NULL", name: :index_good_jobs_on_priority_scheduled_at_unfinished_unlocked
    add_index :good_jobs, :locked_by_id,
      where: "locked_by_id IS NOT NULL", name: "index_good_jobs_on_locked_by_id"
    add_index :good_job_executions, [:process_id, :created_at], name: :index_good_job_executions_on_process_id_and_created_at
  end
  # standard:enable all
end

module Judoscale::Test
end

Dir[File.expand_path("../../judoscale-ruby/test/support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(Judoscale::Test)
