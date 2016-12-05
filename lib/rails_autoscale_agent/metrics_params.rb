require 'rails_autoscale_agent/metric'
require 'rails_autoscale_agent/time_rounder'

module RailsAutoscaleAgent
  class MetricsParams < Struct.new(:metrics)

    def to_a
      [].tap do |result|
        metrics.group_by { |metric| TimeRounder.beginning_of_minute(metric.time) }.each do |time, metrics|
          metrics.group_by { |metric| metric.type }.each do |type, metrics|
            result << {
              time: time.iso8601,
              type: type,
              dyno: ENV['DYNO'],
              values: metrics.map(&:value),
            }
          end
        end
      end
    end

  end
end
