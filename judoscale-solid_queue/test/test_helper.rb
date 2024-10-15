# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Stuff we need to require for SolidQueue
require "rails"
require "active_job/railtie"
# SolidQueue fixed these requires on main, they can be removed eventually
# https://github.com/rails/solid_queue/commit/5ff6e0178bbe7c0cf93134ea2ef974c1dfc09a09
require "active_support"
require "active_support/core_ext/numeric/time"
# It seems SolidQueue v0.7.1+ blows up without requiring activemodel.
# It should be a dependency for them through activerecord, but they may not be requiring it properly.
require "active_model"
require "judoscale-solid_queue"

require "minitest/autorun"
require "minitest/spec"

ENV["RACK_ENV"] ||= "test"
require "action_controller"

class TestRailsApp < Rails::Application
  config.load_defaults "#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}"
  config.secret_key_base = "test-secret"
  config.eager_load = false
  config.logger = ::Logger.new(StringIO.new, progname: "rails-app")
  config.active_job.queue_adapter = :solid_queue
  routes.append do
    root to: proc {
      [200, {"Content-Type" => "text/plain"}, ["Hello World"]]
    }
  end
  initialize!
end

require "active_record"

DATABASE_NAME = "judoscale_solid_queue_test"
DATABASE_USERNAME = "postgres"
DATABASE_URL = "postgres://#{DATABASE_USERNAME}:@localhost/#{DATABASE_NAME}"

ActiveRecord::Tasks::DatabaseTasks.create(DATABASE_URL)
Minitest.after_run {
  ActiveRecord::Tasks::DatabaseTasks.drop(DATABASE_URL)
}
ActiveRecord::Base.configurations = {test: {url: DATABASE_URL}}
ActiveRecord::Base.establish_connection(:test)

# Suppress migration noise.
ENV["VERBOSE"] ||= "false"
# SolidQueue v0.8+ merged migrations into a single schema file, which we load directly into our test DB.
# Migrations are still executed afterwards, as they may add them in the future if schema changes are needed.
SCHEMA_FILE = SolidQueue::Engine.config.paths["lib"].paths.first.join("generators", "solid_queue", "install", "templates", "db", "queue_schema.rb")
ActiveRecord::Tasks::DatabaseTasks.load_schema_current(ActiveRecord.schema_format, SCHEMA_FILE) if SCHEMA_FILE.exist?
# Add SolidQueue migration path to Active Record to migrate to the latest automatically.
# It seems we can't only set it on `DatabaseTasks` as expected, need to set on the `Migrator` directly instead.
ActiveRecord::Migrator.migrations_paths += SolidQueue::Engine.config.paths["db/migrate"].existent
# ActiveRecord::Tasks::DatabaseTasks.migrations_paths += SolidQueue::Engine.config.paths["db/migrate"].existent
ActiveRecord::Tasks::DatabaseTasks.migrate

module Judoscale::Test
end

Dir[File.expand_path("../../judoscale-ruby/test/support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(Judoscale::Test)
