# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rails-autoscale-resque"

require "minitest/autorun"
require "minitest/spec"

module Judoscale::Test
end

Dir[File.expand_path("../../rails-autoscale-core/test/support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(Judoscale::Test)
