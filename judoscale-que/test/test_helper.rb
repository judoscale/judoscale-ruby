# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-que"

require "minitest/autorun"
require "minitest/spec"

require "active_record"

DATABASE_NAME = "judoscale_que_test"
DATABASE_USERNAME = "postgres"
DATABASE_URL = "postgres://#{DATABASE_USERNAME}:@localhost/#{DATABASE_NAME}"

ActiveRecord::Tasks::DatabaseTasks.create(DATABASE_URL)
Minitest.after_run {
  ActiveRecord::Tasks::DatabaseTasks.drop(DATABASE_URL)
}
ActiveRecord::Base.establish_connection(DATABASE_URL)

Que.connection = ActiveRecord
Que::Migrations.migrate!(version: Que::Migrations::CURRENT_VERSION)

module Judoscale::Test
end

Dir[File.expand_path("../../judoscale-ruby/test/support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(Judoscale::Test)
