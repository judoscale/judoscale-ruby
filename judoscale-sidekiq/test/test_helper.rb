# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale-sidekiq"

require "minitest/autorun"
require "minitest/spec"

module Judoscale::Test
end

Dir[File.expand_path("../../judoscale-ruby/test/support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(Judoscale::Test)
