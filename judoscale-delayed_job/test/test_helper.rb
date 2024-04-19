# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-delayed_job"

require "minitest/autorun"
require "minitest/spec"

require "active_record"

DATABASE_NAME = "judoscale_delayed_job_test"
DATABASE_USERNAME = "postgres"
DATABASE_URL = "postgres://#{DATABASE_USERNAME}:@localhost/#{DATABASE_NAME}"

ActiveRecord::Tasks::DatabaseTasks.create(DATABASE_URL)
Minitest.after_run {
  ActiveRecord::Tasks::DatabaseTasks.drop(DATABASE_URL)
}
ActiveRecord::Base.establish_connection(DATABASE_URL)

ActiveRecord::Schema.define do
  # https://github.com/collectiveidea/delayed_job_active_record/blob/master/lib/generators/delayed_job/templates/migration.rb#L3
  # standard:disable all
  suppress_messages do
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

    add_index :delayed_jobs, [:priority, :run_at], name: "delayed_jobs_priority"
  end
  # standard:enable all
end

module Judoscale::Test
end

Dir[File.expand_path("../../judoscale-ruby/test/support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(Judoscale::Test)
