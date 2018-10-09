# frozen_string_literal: true

module RailsAutoscaleAgent
  class TimeRounder

    def self.beginning_of_minute(time)
      Time.new(
        time.year,
        time.month,
        time.day,
        time.hour,
        time.min,
        0,
        time.utc_offset
      )
    end

  end
end
