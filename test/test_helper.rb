# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)
require "judoscale"

require "minitest/autorun"

module Rails
  def self.logger
    @logger ||= ::Logger.new("log/test.log")
  end

  def self.version
    "5.0.fake"
  end
end

module Judoscale
  class Test < Minitest::Test
    def before_setup
      Singleton.__init__(Judoscale::Config) if Object.const_defined?("Judoscale::Config")
      super
    end
  end
end

Dir[File.expand_path("./support/*.rb", __dir__)].sort.each { |file| require file }
