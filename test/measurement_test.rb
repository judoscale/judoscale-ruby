# frozen_string_literal: true

require "time"
require "test_helper"
require "judoscale/measurement"

module Judoscale
  describe Measurement do
    describe "#value" do
      it "is always an Integer" do
        measurement = Measurement.new(:qt, Time.now, 123.45)
        _(measurement.value).must_equal 123
      end
    end

    describe "#time" do
      it "is always in UTC" do
        measurement = Measurement.new(:qt, Time.iso8601("2016-12-03T01:11:00-05:00"), 123)
        _(measurement.time.iso8601).must_equal "2016-12-03T06:11:00Z"
      end
    end
  end
end
