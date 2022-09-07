# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "rails-autoscale-sidekiq"

require "minitest/autorun"
require "minitest/spec"

module RailsAutoscale::Test
end

Dir[File.expand_path("../../rails-autoscale-core/test/support/*.rb", __dir__)].sort.each { |file| require file }

Minitest::Test.include(RailsAutoscale::Test)
