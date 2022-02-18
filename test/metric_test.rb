# frozen_string_literal: true

require "time"
require "test_helper"
require "judoscale/metric"

module Judoscale
  describe Metric do
    describe "#value" do
      it "is always an Integer" do
        metric = Metric.new(:qt, Time.now, 123.45)
        _(metric.value).must_equal 123
      end
    end

    describe "#time" do
      it "is always in UTC" do
        metric = Metric.new(:qt, Time.iso8601("2016-12-03T01:11:00-05:00"), 123)
        _(metric.time.iso8601).must_equal "2016-12-03T06:11:00Z"
      end
    end
  end
end
