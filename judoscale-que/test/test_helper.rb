# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-que"

require "minitest/autorun"
require "minitest/spec"

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

module Judoscale::Test
end

Dir[File.expand_path("../../judoscale-ruby/test/support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(Judoscale::Test)
