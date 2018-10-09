# frozen_string_literal: true

require 'spec_helper'
require 'rails_autoscale_agent/time_rounder'

module RailsAutoscaleAgent
  describe TimeRounder do

    describe ".beginning_of_minute" do
      it "returns a new time rounded to the beginning of the minute" do
        time = Time.iso8601('2016-12-03T01:22:11Z')

        result = TimeRounder.beginning_of_minute(time)

        expect(result.iso8601).to eql '2016-12-03T01:22:00+00:00'
        expect(result).to_not eql time
      end
    end

  end
end
